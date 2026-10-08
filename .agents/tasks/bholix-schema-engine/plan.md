# Implementation Plan — Bholix Schema Engine, Data Layer & UI Scaffolding

## Exploration findings

**Existing codebase** (do not touch):
- `lib/main.dart` — bootstraps `MaterialApp.router(routerConfig: appRouterConfig)`, wires error reporting
- `lib/core/errors/reporter_impl.dart`, `lib/core/utils/sort_extension.dart`, `lib/core/config/**` — fixed
- `lib/routing/app_router.dart` — skeleton with empty `initial:` and empty `switch builder`; MUST be filled in

**Kaisel routing API** (read from `kaisel_core-1.1.0`):
```dart
// Route definition pattern
final class HomeRoute extends AppRoute { const HomeRoute(); }
final class PostRoute extends AppRoute {
  const PostRoute({required this.postUrl});
  final String postUrl;
  @override List<Object?> get props => [postUrl];
}
// Router config
final appRouterConfig = KaiselRouterConfig<AppRoute>(
  initial: const HomeRoute(),
  builder: (context, route) => switch (route) {
    HomeRoute() => const GridPage(),
    PostRoute(:final postUrl) => ProductPage(postUrl: postUrl),
    CartRoute() => const CartPage(),
    LocationPickerRoute() => const LocationPickerPage(),
  },
);
// Imperative navigation
appRouterConfig.router.push(PostRoute(postUrl: url));
appRouterConfig.router.pop();
```

**BLoC/Signal pattern** (read from `bloc_signals-1.5.0`, `signals_flutter-7.1.0`):
```dart
// State: plain immutable class (NOT Dart record — no auto copyWith)
class GridState {
  final List<Map<String,dynamic>> entries;
  final bool isLoading;
  // ... other fields
  const GridState({required this.entries, required this.isLoading, ...});
  GridState copyWith({List<Map<String,dynamic>>? entries, bool? isLoading, ...}) =>
    GridState(entries: entries ?? this.entries, isLoading: isLoading ?? this.isLoading, ...);
}
// BLoC
class GridBloc extends CubitSignal<GridState> {
  GridBloc() : super(initialState: const GridState(...));
  Future<void> loadFeed() async {
    emit(state.value.copyWith(isLoading: true));
    // ...
    emit(state.value.copyWith(entries: results, isLoading: false));
  }
}
// UI — signals_flutter SignalBuilder (NOT deprecated Watch)
SignalBuilder(builder: (context) {
  final s = bloc.state.value;  // tracked automatically
  return ListView(children: [for (final e in s.entries) GridCard(schema: e)]);
})
```

---

## Implementation Plan

- [ ] 1. **Add dependencies to pubspec.yaml**
      Add `http: ^1.2.2`, `cached_network_image: ^3.4.1`, `geolocator: ^13.0.2`, `geocoding: ^3.0.0` under `dependencies:`. Run `flutter pub get`.
      Files: `pubspec.yaml`
      Verify: `flutter pub get` exits 0; no version conflicts.

- [ ] 2. **Create lib/core/schema/schema_override.dart**
      `ResolvedId` class (blogId?, postId?, url? — all nullable String, const constructor).
      `SchemaOverride` utility class with:
      - `static ResolvedId resolveId(String base, String idValue)`: 4-case logic — (1) http/https prefix → `url`, (2) split('/') exactly 2 non-empty → `blogId+postId`, (3) base.contains('/') → `blogId=base.split('/')[0] + postId=idValue`, (4) else → `url`.
      - `static Map<String,dynamic> deepMerge(Map<String,dynamic> target, Map<String,dynamic> source)`: iterate source keys; if both values are non-null non-List Maps → recurse; else source wins.
      Files: `lib/core/schema/schema_override.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 3. **Create lib/core/schema/schema_extractor.dart**
      Static helpers: `getLocalizedValue(dynamic val, Locale? locale)`, `getFirst(dynamic val)`.
      Extractors (each takes `Map<String,dynamic> schema`): `extractName`, `extractDescription`, `extractImage` (→`String?`), `extractImages` (→`List<String>`), `extractPrice` (→`double?`), `extractPriceCurrency`, `extractSku`, `extractBrand`, `extractVariants` (→`List<Map>`), `extractAddons`, `extractAreaServed` (→`List<Map>`), `extractSeller` (→`Map?`), `extractAdditionalProperties` (→`List<Map>`), `extractStockLevel` (→`String?`).
      Static `Locale? currentLocale` settable field.
      Files: `lib/core/schema/schema_extractor.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 4. **Create lib/core/schema/geo_filter.dart** (also defines `LocationData`)
      `LocationData` plain class: `lat, lon, pin, city, state, country` (all `String`); `const` constructor, `fromJson`, `toJson`, `copyWith`, `factory LocationData.empty()`.
      `GeoFilter.isServiceable(dynamic areaServed, LocationData location) → bool`:
      - null/empty → `true`.
      - Normalize to List.
      - Per entry: Country `@type` matching `location.country` → `return true` immediately.
      - PostalCode / `postalCode` value → compare `location.pin`.
      - City / AdministrativeArea → compare `location.city` (case-insensitive).
      - State → compare `location.state`.
      - Plain String → treat as postal code.
      - Any match → `true`; exhausted → `false`.
      Files: `lib/core/schema/geo_filter.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 5. **Create lib/core/services/blogger_config.dart**
      `BloggerAuthMode` enum (`unauthenticated`, `authenticated`).
      `BloggerConfig`: `static const String blogId = String.fromEnvironment('BLOGGER_BLOG_ID', defaultValue: '1774904866501098696')`, `static BloggerAuthMode get currentAuthMode => BloggerAuthMode.unauthenticated` (TODO Firebase), `feedBaseUrl`, `v3BaseUrl` constants.
      Files: `lib/core/services/blogger_config.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 6. **Create lib/core/services/blogger_service.dart**
      Imports: `dart:convert`, `package:http/http.dart as http`, `schema_override.dart`, `blogger_config.dart`.
      `BloggerDataService` class with all methods (see FEAT-001 step 6 for full spec):
      - `static String decodeEntities(String text)` — 8 HTML entity replacements.
      - `Map<String,dynamic>? extractJsonLd(String content)` — script-tag regex primary, `{`…`}` substring fallback.
      - `Future<Map<String,dynamic>?> fetchPostSchema({required String blogId, required String postId})` — unauthenticated GET to feeds API.
      - `Future<Map<String,dynamic>> resolveAndLoadSchema(Map<String,dynamic> schema, {required String base, Set<String>? visited})` — recursive `@id` resolution with cycle guard via `visited Set<String>`. Key per resolved entity is `blogId/postId` or url string. Merges fetched schema into local node using `SchemaOverride.deepMerge`.
      - `Map<String,dynamic> toGraphDocument(List<Map<String,dynamic>> schemas)` — unify `@context`, deduplicate by `@id`, return `{@context, @graph}`.
      - `static String? extractPostIdFromTagId(String tagId)` — split on `.post-`, return last segment.
      - `Future<List<Map<String,dynamic>>> fetchFeed({int maxResults, int startIndex, List<String> labels, String? query})` — label path `/-/label1/label2`, query params, parse entries.
      - `Future<Map<String,dynamic>?> fetchPost({required String postId})` — fetch + resolve.
      - `Future<Map<String,dynamic>?> fetchPostFromUrl(String url)` — GET url as HTML, extractJsonLd from body, resolveAndLoadSchema.
      Files: `lib/core/services/blogger_service.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 7. **Create lib/core/services/location_service.dart**
      Imports `geolocator`, `geocoding`, `path_provider`, `dart:convert`, `dart:io`.
      Import `LocationData` from `geo_filter.dart`.
      `LocationService` with `getCurrentLocation()`, `saveLocation(LocationData)`, `loadLocation() → Future<LocationData?>`, `searchLocation(String query) → Future<List<LocationData>>`.
      Files: `lib/core/services/location_service.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 8. **Create lib/core/services/search_query_builder.dart**
      `SearchQueryBuilder.build({keywords, labels, location})` and `buildFeedUrl({blogId, labels, keywords, location, maxResults, startIndex})`.
      Label splitting: items containing `|` are split and each sub-item treated as a separate label. Labels without `label:` prefix are left as-is (Blogger's label path handles them, not the `q=` param — the `q=` param takes `label:X` terms).
      Files: `lib/core/services/search_query_builder.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 9. **Create lib/core/cart/cart_models.dart**
      `CartAddon` (name, price, qty; fromJson/toJson).
      `OrderItem` (postId, postUrl, name, imageUrl, price, priceCurrency, qty, variantId?, packageId?, addons; fromJson/toJson/copyWith).
      `CartOrder` (items, priceCurrency; fromJson/toJson; `double get totalPrice`; `factory CartOrder.empty()`).
      Files: `lib/core/cart/cart_models.dart`
      Verify: `flutter analyze` — 0 errors.

- [ ] 10. **Create lib/core/cart/cart_repository.dart**
       CRUD over `documentsDir/antinna_cart.json` using `CartOrder` JSON.
       Methods: `load`, `_save`, `addItem`, `removeItem`, `updateQty`, `clear`.
       Files: `lib/core/cart/cart_repository.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 11. **Create lib/core/wishlist/wishlist_repository.dart**
       CRUD over `documentsDir/antinna_wishlist.json` as `List<String>` postIds.
       Methods: `_load`, `_save`, `add`, `remove`, `contains`.
       Files: `lib/core/wishlist/wishlist_repository.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 12. **Create lib/features/grid/grid_bloc.dart**
       `GridState` class (entries, isLoading, hasMore, labels, searchKeywords, location; copyWith).
       `GridBloc extends CubitSignal<GridState>` with `loadFeed()`, `loadMore()`, `setLabels()`, `setSearch()`, `setLocation()`.
       `loadFeed`/`loadMore` call `BloggerDataService().fetchFeed(...)` then filter with `GeoFilter.isServiceable`.
       Files: `lib/features/grid/grid_bloc.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 13. **Create lib/features/product/product_bloc.dart**
       `ProductState` class (schema?, isLoading, selectedVariant?, selectedPackage?, qty; copyWith).
       `ProductBloc extends CubitSignal<ProductState>` with `loadPost(postId)`, `loadPostFromUrl(url)`, `selectVariant`, `selectPackage`, `setQty`, `addToCart(CartRepository)`, `addToWishlist(WishlistRepository)`.
       Files: `lib/features/product/product_bloc.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 14. **Create lib/features/cart/cart_bloc.dart**
       `CartBloc extends CubitSignal<CartOrder>` (state is `CartOrder` directly).
       Constructor takes `CartRepository`. Methods: `loadCart`, `addItem`, `removeItem`, `updateQty`, `clearCart`.
       Files: `lib/features/cart/cart_bloc.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 15. **Create lib/features/location/location_bloc.dart**
       `LocationState` class (location?, isLoading; copyWith).
       `LocationBloc extends CubitSignal<LocationState>` with `loadSaved`, `requestGps`, `setManual`, `clear`.
       Constructor takes `LocationService`.
       Files: `lib/features/location/location_bloc.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 16. **Create product sub-widgets** (all 6 files, same pattern)
       Each is a small `StatelessWidget` or `StatefulWidget`:
       - `lib/features/product/widgets/stock_badge.dart` — `StockBadge(String? availability)` → green/red Chip.
       - `lib/features/product/widgets/image_carousel.dart` — `ImageCarousel(List<String> imageUrls)` → PageView + CachedNetworkImage + dot indicator.
       - `lib/features/product/widgets/variant_selector.dart` — `VariantSelector` → Wrap of Chips, selected highlighted.
       - `lib/features/product/widgets/addon_section.dart` — `AddonSection` → CheckboxListTile per addon.
       - `lib/features/product/widgets/seller_card.dart` — `SellerCard(Map? seller)` → Card with contact info.
       - `lib/features/product/widgets/specs_section.dart` — `SpecsSection(List<Map> properties)` → key-value Column.
       Files: 6 files as listed above.
       Verify: `flutter analyze` — 0 errors.

- [ ] 17. **Create lib/features/search/search_bar_widget.dart**
       `SearchBarWidget({required void Function(List<String> keywords, List<String> labels) onSearch})`.
       Parse `|` in input to split into multiple labels. Extract `label:X` terms as labels. Active label chips with delete. Dark/cyan theme consistent.
       Files: `lib/features/search/search_bar_widget.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 18. **Create lib/features/grid/grid_card.dart**
       `GridCard({required Map<String,dynamic> schema, required VoidCallback onTap})`.
       CachedNetworkImage thumbnail, name, price+currency, StockBadge, first areaServed chip.
       Tapping calls `onTap` (caller provides navigation).
       Files: `lib/features/grid/grid_card.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 19. **Create lib/features/grid/grid_page.dart**
       `GridPage` StatefulWidget. Creates `GridBloc` and `LocationBloc` in `initState`. Calls `bloc.loadFeed()` on init.
       AppBar: title `SearchBarWidget`, actions: location chip button → `appRouterConfig.router.push(const LocationPickerRoute())`.
       Body: `SignalBuilder` over `bloc.state` → `GridView.builder(crossAxisCount: 2, ...)` with `GridCard` entries.
       Scroll controller triggers `bloc.loadMore()` near bottom. Loading indicator at list end when `hasMore && isLoading`.
       `GridCard.onTap` → `appRouterConfig.router.push(PostRoute(postUrl: schema['url'] ?? schema['@id'] ?? ''))`.
       Files: `lib/features/grid/grid_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 20. **Create lib/features/product/product_page.dart**
       `ProductPage({required String postUrl})` StatefulWidget. Creates `ProductBloc`, `CartRepository`, `WishlistRepository` in `initState`. Calls `bloc.loadPostFromUrl(postUrl)`.
       Layout: CustomScrollView with SliverAppBar containing ImageCarousel, SliverList with: name, description, price row + StockBadge, VariantSelector, AddonSection, SellerCard, SpecsSection.
       Bottom bar: qty stepper + 'Add to Cart' + 'Add to Wishlist'.
       All wrapped in `SignalBuilder` on `bloc.state`.
       Files: `lib/features/product/product_page.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 21. **Create cart sheet/page and location picker sheet/page**
       `lib/features/cart/cart_item_tile.dart` — ListTile with image, name, price, qty stepper, delete.
       `lib/features/cart/cart_sheet.dart` — Column/ListView of CartItemTile, total bar, Checkout stub, Clear Cart. Accepts `CartBloc` param.
       `lib/features/cart/cart_page.dart` — Scaffold wrapping `CartSheet`, creates `CartBloc(CartRepository())` in `initState`, calls `bloc.loadCart()`.
       `lib/features/location/location_picker_sheet.dart` — TextField (debounced search), GPS button, results list. Accepts `LocationBloc` param.
       `lib/features/location/location_picker_page.dart` — Scaffold wrapping `LocationPickerSheet`, creates `LocationBloc(LocationService())`.
       Files: 5 files as listed.
       Verify: `flutter analyze` — 0 errors.

- [ ] 22. **Fill in lib/routing/app_router.dart**
       Add 4 route classes (`HomeRoute`, `PostRoute`, `CartRoute`, `LocationPickerRoute`) above the existing `appRouterConfig` declaration.
       Fill `initial: const HomeRoute()` and the exhaustive switch builder mapping all 4 routes to their page widgets.
       Import the 4 page files.
       Files: `lib/routing/app_router.dart`
       Verify: `flutter analyze` — 0 errors.

- [ ] 23. **Add Android permissions to AndroidManifest.xml**
       Insert before `<application`:
       ```xml
       <uses-permission android:name="android.permission.INTERNET"/>
       <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
       <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
       ```
       Files: `android/app/src/main/AndroidManifest.xml`
       Verify: `flutter build apk --debug` — exits 0.

- [ ] 24. **Full build verification**
       Run `flutter analyze` and `flutter build apk --debug`.
       Fix any remaining type errors, missing imports, or exhaustiveness warnings.
       Files: any files with remaining errors.
       Verify: both commands exit 0 with no errors.

---

## Implementation notes for tricky parts

### Kaisel router — exhaustive switch requirement
The `builder` in `KaiselRouterConfig` is `KaiselPageBuilder<R>` which is `Widget Function(BuildContext, R)`. The switch must be exhaustive over the sealed `AppRoute` hierarchy. Every `final class X extends AppRoute` that exists must have a case, or the Dart compiler will error. Add all 4 routes before filling the switch.

### bloc_signals — CubitSignal pattern
Blocs extend `CubitSignal<S>` directly (it calls `initCubitSignal` in its own constructor). In subclasses call `super(initialState: ...)`. Do not call `initCubitSignal` manually. Use `state.value` to read current state, `emit(newState)` to update. `state` is `ReadonlySignal<S>` — read with `.value` inside `SignalBuilder` to auto-subscribe.

### SignalBuilder vs Watch
`Watch` is deprecated. Use `SignalBuilder(builder: (context) { ... })` — any `signal.value` accessed synchronously inside the builder is auto-tracked.

### LocationData placement
`LocationData` is defined in `lib/core/schema/geo_filter.dart`. `LocationService` imports it from there. No duplication.

### Cycle detection in resolveAndLoadSchema
Track visited keys in `Set<String>`. Key format: `"blogId/postId"` for Blogger refs or the full URL for HTTP refs. Before fetching: check `visited.contains(key)`. After deciding to fetch: `visited.add(key)`. Pass `visited` through recursive calls.

### PostRoute carries postUrl not postId
`ProductPage` receives a full alternate URL (e.g. `https://bholix.blogspot.com/2024/06/slug.html`). `ProductBloc.loadPostFromUrl(url)` GETs the page HTML, calls `extractJsonLd`, then `resolveAndLoadSchema`. The `@id` inside the schema may contain `blogId/postId` which `resolveAndLoadSchema` will recursively fetch via the Blogger feeds API.

### Label power search parsing
In `SearchBarWidget`, text like `electronics|phones` or `label:electronics label:phones` should produce labels `['electronics', 'phones']`. Split on `|`, trim each, strip `label:` prefix if present. These become path segments in the feed URL (`/-/electronics/phones`).

### Android geocoding requirement
`geocoding` plugin requires `INTERNET` permission (already being added). `geolocator` requires `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`. All three are added in step 23.
