extension SchwartzianSortExtension<T> on Iterable<T> {
  /// Sorts elements by an expensive key using the Schwartzian Transform
  /// (Decorate-Sort-Undecorate).
  ///
  /// Guarantees that [keyOf] is invoked **exactly once** per element (O(N) calls),
  /// caching the derived keys in lightweight Dart 3 records during sorting.
  List<T> sortedByExpensive<K extends Comparable<K>>(K Function(T item) keyOf) {
    final boxed = [for (final item in this) (key: keyOf(item), item: item)]
      ..sort((a, b) => a.key.compareTo(b.key));

    return [for (final entry in boxed) entry.item];
  }

  /// Sorts elements by an expensive key using a custom [compare] function.
  List<T> sortedByCompareExpensive<K>(
    K Function(T item) keyOf,
    int Function(K a, K b) compare,
  ) {
    final boxed = [for (final item in this) (key: keyOf(item), item: item)]
      ..sort((a, b) => compare(a.key, b.key));

    return [for (final entry in boxed) entry.item];
  }
}
