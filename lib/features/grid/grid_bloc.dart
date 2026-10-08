import 'package:bloc_signals/bloc_signals.dart';

import '../../core/schema/geo_filter.dart';
import '../../core/services/blogger_service.dart';

class GridState {
  final List<Map<String, dynamic>> entries;
  final bool isLoading;
  final bool hasMore;
  final List<String> activeLabels;
  final String searchKeywords;
  final LocationData? location;
  final String? error;

  const GridState({
    this.entries = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.activeLabels = const [],
    this.searchKeywords = '',
    this.location,
    this.error,
  });

  GridState copyWith({
    List<Map<String, dynamic>>? entries,
    bool? isLoading,
    bool? hasMore,
    List<String>? activeLabels,
    String? searchKeywords,
    LocationData? location,
    bool clearLocation = false,
    String? error,
    bool clearError = false,
  }) {
    return GridState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      activeLabels: activeLabels ?? this.activeLabels,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      location: clearLocation ? null : (location ?? this.location),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GridBloc extends CubitSignal<GridState> {
  static const _pageSize = 20;

  GridBloc() : super(initialState: const GridState());

  Future<void> loadFeed() async {
    emit(stateValue.copyWith(isLoading: true, clearError: true));

    try {
      final service = BloggerDataService();
      final raw = await service.fetchFeed(
        maxResults: _pageSize,
        startIndex: 1,
        labels: stateValue.activeLabels,
        query: stateValue.searchKeywords.isNotEmpty
            ? stateValue.searchKeywords
            : null,
      );

      final filtered = _applyGeoFilter(raw);

      emit(stateValue.copyWith(
        entries: filtered,
        isLoading: false,
        hasMore: raw.length == _pageSize,
      ));
    } catch (e) {
      emit(stateValue.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMore() async {
    if (stateValue.isLoading || !stateValue.hasMore) return;

    emit(stateValue.copyWith(isLoading: true));

    try {
      final service = BloggerDataService();
      final raw = await service.fetchFeed(
        maxResults: _pageSize,
        startIndex: stateValue.entries.length + 1,
        labels: stateValue.activeLabels,
        query: stateValue.searchKeywords.isNotEmpty
            ? stateValue.searchKeywords
            : null,
      );

      final filtered = _applyGeoFilter(raw);

      emit(stateValue.copyWith(
        entries: [...stateValue.entries, ...filtered],
        isLoading: false,
        hasMore: raw.length == _pageSize,
      ));
    } catch (e) {
      emit(stateValue.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void setLabels(List<String> labels) {
    emit(stateValue.copyWith(activeLabels: labels));
  }

  void setSearch(String keywords) {
    emit(stateValue.copyWith(searchKeywords: keywords));
  }

  void setLocation(LocationData? location) {
    if (location == null) {
      emit(stateValue.copyWith(clearLocation: true));
    } else {
      emit(stateValue.copyWith(location: location));
    }
  }

  List<Map<String, dynamic>> _applyGeoFilter(
      List<Map<String, dynamic>> entries) {
    final loc = stateValue.location;
    if (loc == null) return entries;

    return entries.where((schema) {
      final areaServed = schema['areaServed'];
      return GeoFilter.isServiceable(areaServed, loc);
    }).toList();
  }
}
