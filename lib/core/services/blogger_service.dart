import 'dart:convert';

import 'package:http/http.dart' as http;

import '../schema/schema_override.dart';
import 'blogger_config.dart';

/// Service for fetching Blogger post JSON feeds, parsing JSON-LD,
/// recursively resolving @id entities, merging local property overrides,
/// and outputting clean JSON-LD @graph documents.
class BloggerDataService {
  // ── Entity decoding ─────────────────────────────────────────────────────────

  /// Decodes common HTML entities found in Blogger post bodies.
  static String decodeEntities(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#91;', '[')
        .replaceAll('&#93;', ']');
  }

  // ── JSON-LD extraction ──────────────────────────────────────────────────────

  /// Extracts JSON-LD from a post content string (with or without script tags).
  ///
  /// Tries two strategies:
  /// 1. Regex for `<script type="application/ld+json">…</script>`.
  /// 2. Substring from the first `{` to the last `}` as a fallback.
  Map<String, dynamic>? extractJsonLd(String content) {
    if (content.isEmpty) return null;

    // Strategy 1: look for a JSON-LD script block.
    try {
      final scriptRegex = RegExp(
        '<script[^>]*type=["\']application/ld\\+json["\'][^>]*>([\\s\\S]*?)</script>',
        caseSensitive: false,
      );
      final match = scriptRegex.firstMatch(content);
      String jsonContent = match != null ? match.group(1)! : content;

      jsonContent = decodeEntities(jsonContent).trim();

      // Strip /* … */ comments (used occasionally in JSON-LD).
      final cleaned = jsonContent
          .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Strategy 2: raw substring fallback.
      try {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          final candidate = decodeEntities(content.substring(start, end + 1));
          return jsonDecode(candidate) as Map<String, dynamic>;
        }
      } catch (_) {
        // Both strategies failed — fall through.
      }
    }

    return null;
  }

  // ── Single-post fetch ───────────────────────────────────────────────────────

  /// Fetches a Blogger post's Atom/JSON feed and returns its extracted JSON-LD.
  ///
  /// Uses the unauthenticated feed endpoint:
  /// `https://www.blogger.com/feeds/{blogId}/posts/default/{postId}?alt=json`
  Future<Map<String, dynamic>?> fetchPostSchema({
    required String blogId,
    required String postId,
  }) async {
    final url = Uri.parse(
      '${BloggerConfig.feedBaseUrl}/$blogId/posts/default/$postId?alt=json',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final entry = data['entry'] as Map<String, dynamic>?;
      if (entry == null) return null;

      final content =
          (entry['content'] as Map<String, dynamic>?)?[r'$t'] as String? ?? '';
      return extractJsonLd(content);
    } catch (e) {
      return null;
    }
  }

  // ── Recursive @id resolution ────────────────────────────────────────────────

  /// Recursively resolves all @id references in [schema], fetches remote
  /// schemas, and deep-merges local overrides.
  ///
  /// [visited] tracks already-processed keys to break cycles.
  Future<Map<String, dynamic>> resolveAndLoadSchema(
    Map<String, dynamic> schema, {
    required String base,
    Set<String>? visited,
  }) async {
    visited ??= {};
    // Work on a deep clone so we never mutate the caller's map.
    final resolved = jsonDecode(jsonEncode(schema)) as Map<String, dynamic>;

    // Extract @base from document or @context if present, falling back to base parameter
    final documentBase = SchemaOverride.extractBase(resolved) ?? base;

    await _traverseAndResolve(resolved, documentBase, visited);
    return resolved;
  }

  Future<void> _traverseAndResolve(
    dynamic node,
    String base,
    Set<String> visited,
  ) async {
    if (node is! Map<String, dynamic>) {
      if (node is List) {
        for (final item in node) {
          await _traverseAndResolve(item, base, visited);
        }
      }
      return;
    }

    final idValue = node['@id'];
    if (idValue is String && idValue.trim().isNotEmpty) {
      final resolvedId = SchemaOverride.resolveId(base, idValue);
      final blogId = resolvedId.blogId;
      final postId = resolvedId.postId;
      final fullUrl = resolvedId.url;

      // Build a stable cycle-detection key.
      final cycleKey = (blogId != null && postId != null)
          ? '$blogId/$postId'
          : fullUrl;

      if (cycleKey != null && !visited.contains(cycleKey)) {
        visited.add(cycleKey);

        Map<String, dynamic>? fetchedSchema;

        if (blogId != null && postId != null) {
          fetchedSchema = await fetchPostSchema(blogId: blogId, postId: postId);
        } else if (fullUrl != null) {
          try {
            final res = await http.get(Uri.parse(fullUrl));
            if (res.statusCode == 200) {
              fetchedSchema = extractJsonLd(res.body);
            }
          } catch (_) {
            // Network failure — skip this reference.
          }
        }

        if (fetchedSchema != null) {
          final nestedBase = (blogId != null && postId != null)
              ? '$blogId/$postId'
              : base;

          // Recursively resolve the fetched schema too.
          fetchedSchema = await resolveAndLoadSchema(
            fetchedSchema,
            base: nestedBase,
            visited: visited,
          );

          // Merge fetched schema into current node (local properties win).
          final merged = SchemaOverride.deepMerge(fetchedSchema, node);
          merged.remove('@id'); // Prevent infinite re-resolution.

          // Copy merged keys back into the in-place node map.
          node
            ..clear()
            ..addAll(merged);
        }
      }
    }

    // Recurse into all child values (after potential @id resolution above).
    for (final key in List<String>.from(node.keys)) {
      await _traverseAndResolve(node[key], base, visited);
    }
  }

  // ── Graph document builder ──────────────────────────────────────────────────

  /// Combines multiple resolved schemas into a single JSON-LD @graph document.
  ///
  /// - Merges all @context objects (string contexts become `{'@vocab': value}`).
  /// - Deduplicates nodes by '@id' (last definition wins).
  /// - Strips @context from individual graph nodes.
  Map<String, dynamic> toGraphDocument(List<Map<String, dynamic>> schemas) {
    final unifiedContext = <String, dynamic>{};
    final deduped = <String, Map<String, dynamic>>{};

    for (final schema in schemas) {
      // Merge @context.
      final ctx = schema['@context'];
      if (ctx is Map<String, dynamic>) {
        unifiedContext.addAll(ctx);
      } else if (ctx is String) {
        unifiedContext['@vocab'] = ctx;
      }

      // Build a copy without @context.
      final node = Map<String, dynamic>.from(schema)..remove('@context');

      // Deduplicate and deep-merge by @id.
      final id = node['@id'] as String?;
      if (id != null) {
        if (deduped.containsKey(id)) {
          deduped[id] = SchemaOverride.deepMerge(deduped[id]!, node);
        } else {
          deduped[id] = node;
        }
      } else {
        // No @id — use insertion-order key to keep the node.
        deduped['_noId_${deduped.length}'] = node;
      }
    }

    return {'@context': unifiedContext, '@graph': deduped.values.toList()};
  }

  // ── Post-ID extraction ──────────────────────────────────────────────────────

  /// Extracts the numeric post ID from a Blogger tag-style `id` string.
  ///
  /// Example:
  /// `tag:blogger.com,1999:blog-1774904866501098696.post-5522904867501094455`
  /// → `'5522904867501094455'`
  static String? extractPostIdFromTagId(String tagId) {
    const separator = '.post-';
    final idx = tagId.lastIndexOf(separator);
    if (idx == -1) return null;
    final postId = tagId.substring(idx + separator.length);
    return postId.isEmpty ? null : postId;
  }

  // ── Feed fetch ──────────────────────────────────────────────────────────────

  /// Fetches a page of posts from the Blogger JSON feed.
  ///
  /// [labels]    — filter by one or more Blogger labels.
  /// [query]     — full-text / label power-search query string.
  /// [maxResults] / [startIndex] — pagination.
  Future<List<Map<String, dynamic>>> fetchFeed({
    int maxResults = 20,
    int startIndex = 1,
    List<String> labels = const [],
    String? query,
  }) async {
    final blogId = BloggerConfig.blogId;

    // Build path: /.../posts/default[/-/label1/label2]
    final labelPath = labels.isNotEmpty ? '/-/${labels.join('/')}' : '';
    final basePath =
        '${BloggerConfig.feedBaseUrl}/$blogId/posts/default$labelPath';

    // Build query parameters.
    final params = <String, String>{
      'alt': 'json',
      'max-results': maxResults.toString(),
      'start-index': startIndex.toString(),
    };
    if (query != null && query.isNotEmpty) params['q'] = query;

    final uri = Uri.parse(basePath).replace(queryParameters: params);

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final feed = data['feed'] as Map<String, dynamic>?;
      if (feed == null) return [];

      final entries = (feed['entry'] as List<dynamic>?) ?? [];
      final result = <Map<String, dynamic>>[];

      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) continue;

        // Extract post ID from the tag-style id field.
        final idField =
            (entry['id'] as Map<String, dynamic>?)?[r'$t'] as String?;
        final postId = idField != null ? extractPostIdFromTagId(idField) : null;

        // Find alternate link.
        final links = entry['link'] as List<dynamic>? ?? [];
        String? alternateUrl;
        for (final link in links) {
          if (link is Map && link['rel'] == 'alternate') {
            alternateUrl = link['href'] as String?;
            break;
          }
        }

        // Extract JSON-LD from content.
        final content =
            (entry['content'] as Map<String, dynamic>?)?[r'$t'] as String?;
        if (content == null) continue;

        final schema = extractJsonLd(content);
        if (schema == null) continue;

        // Resolve @id references recursively (uses base = blogId/postId).
        final base = (postId != null)
            ? '${BloggerConfig.blogId}/$postId'
            : BloggerConfig.blogId;
        final resolved = await resolveAndLoadSchema(schema, base: base);

        // Embed meta fields useful for the UI layer.
        if (postId != null) resolved['_postId'] = postId;
        if (alternateUrl != null) resolved['_alternateUrl'] = alternateUrl;

        result.add(resolved);
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  // ── Single-post high-level fetch ────────────────────────────────────────────

  /// Fetches and fully resolves a single post by [postId].
  ///
  /// Returns the resolved schema, or null if the post cannot be loaded.
  Future<Map<String, dynamic>?> fetchPost({required String postId}) async {
    final blogId = BloggerConfig.blogId;
    final schema = await fetchPostSchema(blogId: blogId, postId: postId);
    if (schema == null) return null;

    return resolveAndLoadSchema(schema, base: '$blogId/$postId');
  }
}
