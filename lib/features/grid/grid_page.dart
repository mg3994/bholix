import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

import '../../core/cart/cart_provider.dart';
import '../../core/services/location_service.dart';
import '../../routing/app_router.dart';
import '../cart/cart_bloc.dart';
import '../location/location_bloc.dart';
import '../search/search_bar_widget.dart';
import 'grid_bloc.dart';
import 'grid_card.dart';

class GridPage extends StatefulWidget {
  const GridPage({super.key});

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  late final GridBloc _gridBloc;
  late final LocationBloc _locationBloc;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _locationBloc = LocationBloc(LocationService());
    _gridBloc = GridBloc();

    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitial() async {
    await _locationBloc.loadSaved();
    final loc = _locationBloc.stateValue.location;
    if (loc != null) _gridBloc.setLocation(loc);
    await _gridBloc.loadFeed();
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    await context.push(const LocationPickerRoute());
    // After returning, reload saved location and refresh feed.
    await _locationBloc.loadSaved();
    final loc = _locationBloc.stateValue.location;
    _gridBloc.setLocation(loc);
    _gridBloc.loadFeed();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _gridBloc.loadMore();
    }
  }

  @override
  void dispose() {
    _gridBloc.close();
    _locationBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(List<String> keywords, List<String> labels) {
    _gridBloc
      ..setSearch(keywords.join(' '))
      ..setLabels(labels);
    _gridBloc.loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final cartBloc = CartProvider.of(context);
    return BlocSignalBuilder<GridBloc, GridState>(
      bloc: _gridBloc,
      builder: (ctx, gridState) {
        return BlocSignalBuilder<LocationBloc, LocationState>(
          bloc: _locationBloc,
          builder: (ctx, locState) {
            return BlocSignalBuilder<CartBloc, CartOrder>(
              bloc: cartBloc,
              builder: (ctx, cartOrder) {
                return Scaffold(
                  backgroundColor: const Color(0xFF0f0f0f),
                  appBar: _GridAppBar(
                    locState: locState,
                    onSearch: _onSearch,
                    onLocationTap: () => _openLocationPicker(context),
                    cartCount: cartOrder.items.fold(0, (s, i) => s + i.qty),
                    onCartTap: () => context.push(const CartRoute()),
                  ),
                  body: _GridBody(
                    state: gridState,
                    scrollController: _scrollController,
                    onCardTap: (url) => context.push(PostRoute(postUrl: url)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GridAppBar extends StatelessWidget implements PreferredSizeWidget {
  final LocationState locState;
  final void Function(List<String> keywords, List<String> labels) onSearch;
  final VoidCallback onLocationTap;
  final int cartCount;
  final VoidCallback onCartTap;

  const _GridAppBar({
    required this.locState,
    required this.onSearch,
    required this.onLocationTap,
    required this.cartCount,
    required this.onCartTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(110);

  @override
  Widget build(BuildContext context) {
    final city = locState.location?.city;
    final locationLabel = (city != null && city.isNotEmpty)
        ? city
        : 'Set Location';

    return AppBar(
      backgroundColor: const Color(0xFF1a1a1a),
      toolbarHeight: 110,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: SearchBarWidget(onSearch: onSearch)),
                  const SizedBox(width: 8),
                  _CartBadge(count: cartCount, onTap: onCartTap),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onLocationTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      locationLabel,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: Colors.cyanAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.cyanAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GridBody extends StatelessWidget {
  final GridState state;
  final ScrollController scrollController;
  final void Function(String postUrl) onCardTap;

  const _GridBody({
    required this.state,
    required this.scrollController,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (state.error != null && state.entries.isEmpty) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.entries.isEmpty) {
      return const Center(
        child: Text(
          'No products found',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: state.entries.map((schema) {
              final url = (schema['_alternateUrl'] as String?) ?? '';
              return GridCard(schema: schema, postUrl: url, onTap: onCardTap);
            }).toList(),
          ),
        ),
        if (state.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}
