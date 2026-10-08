/// Manages pagination state for Blogger post feeds (startIndex, maxResults, hasMore).
class PaginationManager {
  final int maxResults;
  int startIndex;
  bool hasMore;
  bool isLoading;

  PaginationManager({
    this.maxResults = 20,
    this.startIndex = 1,
    this.hasMore = true,
    this.isLoading = false,
  });

  /// Resets pagination state to initial values.
  void reset() {
    startIndex = 1;
    hasMore = true;
    isLoading = false;
  }

  /// Advances start index after a successful fetch with [fetchedCount] items.
  void advance(int fetchedCount) {
    startIndex += fetchedCount;
    if (fetchedCount < maxResults) {
      hasMore = false;
    }
  }

  /// Calculates next start index.
  int get nextStartIndex => startIndex;
}
