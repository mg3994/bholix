/// Interface representing resolved target location from an @id reference.
class ResolvedId {
  final String? blogId;
  final String? postId;
  final String? url;

  const ResolvedId({this.blogId, this.postId, this.url});

  @override
  String toString() =>
      'ResolvedId(blogId: $blogId, postId: $postId, url: $url)';

  @override
  bool operator ==(Object other) =>
      other is ResolvedId &&
      other.blogId == blogId &&
      other.postId == postId &&
      other.url == url;

  @override
  int get hashCode => Object.hash(blogId, postId, url);
}

/// Utility class for handling @id path resolution and deep merging object schemas.
class SchemaOverride {
  /// Resolves an @id value relative to a base path or as an absolute URL.
  ///
  /// Four-case logic:
  /// 1. Absolute HTTP/HTTPS URL → ResolvedId(url: idValue)
  /// 2. Exactly "blogId/postId" (two non-empty parts) → ResolvedId(blogId, postId)
  /// 3. base contains '/' → ResolvedId(blogId: base.split('/')[0], postId: idValue)
  /// 4. Fallback → ResolvedId(url: idValue)
  static ResolvedId resolveId(String base, String idValue) {
    if (idValue.isEmpty) return const ResolvedId();

    // 1. Full absolute HTTP/HTTPS URL.
    if (idValue.startsWith('http://') || idValue.startsWith('https://')) {
      return ResolvedId(url: idValue);
    }

    // 2. Direct "blogId/postId" path string.
    final parts = idValue.split('/');
    if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return ResolvedId(blogId: parts[0], postId: parts[1]);
    }

    // 3. Relative ID against a base "blogId/postId" context.
    if (base.contains('/') &&
        !base.startsWith('http://') &&
        !base.startsWith('https://')) {
      final baseParts = base.split('/');
      if (baseParts[0].isNotEmpty) {
        return ResolvedId(blogId: baseParts[0], postId: idValue);
      }
    }

    // 4. Relative ID against a base absolute URL.
    if (base.startsWith('http://') || base.startsWith('https://')) {
      final baseUri = Uri.tryParse(base);
      if (baseUri != null) {
        return ResolvedId(url: baseUri.resolve(idValue).toString());
      }
    }

    // 5. Fallback.
    return ResolvedId(url: idValue);
  }

  /// Deep merges two JSON objects. Source properties override target properties.
  /// When both values are non-null, non-List Maps, they are merged recursively.
  static Map<String, dynamic> deepMerge(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    final output = Map<String, dynamic>.from(target);

    for (final key in source.keys) {
      final targetVal = target[key];
      final sourceVal = source[key];

      if (sourceVal is Map<String, dynamic> &&
          targetVal is Map<String, dynamic>) {
        output[key] = deepMerge(targetVal, sourceVal);
      } else {
        output[key] = sourceVal;
      }
    }

    return output;
  }

  /// Extracts `@base` from schema map or its `@context`.
  static String? extractBase(Map<String, dynamic> schema) {
    if (schema.containsKey('@base') && schema['@base'] is String) {
      return schema['@base'] as String;
    }
    final ctx = schema['@context'];
    if (ctx is Map<String, dynamic>) {
      if (ctx.containsKey('@base') && ctx['@base'] is String) {
        return ctx['@base'] as String;
      }
    }
    return null;
  }

  /// Extracts default `@language` from schema map or its `@context`.
  static String? extractDefaultLanguage(Map<String, dynamic> schema) {
    if (schema.containsKey('@language') && schema['@language'] is String) {
      return schema['@language'] as String;
    }
    final ctx = schema['@context'];
    if (ctx is Map<String, dynamic>) {
      if (ctx.containsKey('@language') && ctx['@language'] is String) {
        return ctx['@language'] as String;
      }
    }
    return null;
  }
}
