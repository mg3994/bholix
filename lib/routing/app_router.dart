import 'package:kaisel/kaisel.dart';

import '../features/cart/cart_page.dart';
import '../features/grid/grid_page.dart';
import '../features/location/location_picker_page.dart';
import '../features/product/product_page.dart';

// ── Sealed route hierarchy ────────────────────────────────────────────────────

sealed class AppRoute extends KaiselRoute {
  const AppRoute();
}

/// Home / grid listing route.
final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  List<Object?> get props => [];
}

/// Product detail route.
final class PostRoute extends AppRoute {
  final String postUrl;

  const PostRoute({required this.postUrl});

  @override
  List<Object?> get props => [postUrl];
}

/// Full-page cart route.
final class CartRoute extends AppRoute {
  const CartRoute();

  @override
  List<Object?> get props => [];
}

/// Location picker route.
final class LocationPickerRoute extends AppRoute {
  const LocationPickerRoute();

  @override
  List<Object?> get props => [];
}

// ── App-lifetime router config ─────────────────────────────────────────────────

final appRouterConfig = KaiselRouterConfig<AppRoute>(
  initial: const HomeRoute(),
  builder: (context, route) => switch (route) {
    HomeRoute() => const GridPage(),
    PostRoute(:final postUrl) => ProductPage(postUrl: postUrl),
    CartRoute() => const CartPage(),
    LocationPickerRoute() => const LocationPickerPage(),
  },
);
