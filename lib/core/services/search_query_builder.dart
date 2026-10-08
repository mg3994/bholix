import '../schema/geo_filter.dart';

/// Builds Blogger feed query strings and URLs for the power-search UI.
class SearchQueryBuilder {
  /// Builds a space-separated search query string from [keywords], [labels],
  /// and an optional [location].
  ///
  /// - Each label that does not already begin with `label:` is prefixed with it.
  /// - Location contributes `postalCode:<pin>` (preferred) or
  ///   `addressLocality:<city>` when the other is empty.
  static String build({
    List<String> keywords = const [],
    List<String> labels = const [],
    LocationData? location,
  }) {
    final parts = <String>[];

    for (final kw in keywords) {
      final trimmed = kw.trim();
      if (trimmed.isNotEmpty) parts.add(trimmed);
    }

    for (final label in labels) {
      final trimmed = label.trim();
      if (trimmed.isEmpty) continue;
      parts.add(trimmed.startsWith('label:') ? trimmed : 'label:$trimmed');
    }

    if (location != null) {
      if (location.pin.isNotEmpty) {
        parts.add('postalCode:${location.pin}');
      } else if (location.city.isNotEmpty) {
        parts.add('addressLocality:${location.city}');
      }
    }

    return parts.join(' ');
  }

  /// Builds a full Blogger feed URL for [blogId] with optional label routing,
  /// keyword/location query param, and pagination.
  static String buildFeedUrl({
    required String blogId,
    List<String> labels = const [],
    List<String> keywords = const [],
    LocationData? location,
    int maxResults = 20,
    int startIndex = 1,
  }) {
    var path = 'https://www.blogger.com/feeds/$blogId/posts/default';

    // Blogger label routing: /-/label1/label2/...
    final cleanLabels = labels
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (cleanLabels.isNotEmpty) {
      path += '/-/${cleanLabels.join('/')}';
    }

    final Map<String, String> queryParams = {
      'alt': 'json',
      'max-results': maxResults.toString(),
      'start-index': startIndex.toString(),
    };

    final q = build(keywords: keywords, location: location);
    if (q.isNotEmpty) {
      queryParams['q'] = q;
    }

    final uri = Uri.parse(path).replace(queryParameters: queryParams);
    return uri.toString();
  }
}
