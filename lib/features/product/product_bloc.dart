import 'package:bloc_signals/bloc_signals.dart';
import 'package:http/http.dart' as http;

import '../../core/cart/cart_repository.dart';
import '../../core/services/blogger_service.dart';
import '../../core/wishlist/wishlist_repository.dart';

class ProductState {
  final Map<String, dynamic>? schema;
  final bool isLoading;
  final Map<String, dynamic>? selectedVariant;
  final Map<String, dynamic>? selectedPackage;
  final int qty;
  final String? error;

  const ProductState({
    this.schema,
    this.isLoading = false,
    this.selectedVariant,
    this.selectedPackage,
    this.qty = 1,
    this.error,
  });

  ProductState copyWith({
    Map<String, dynamic>? schema,
    bool? isLoading,
    Map<String, dynamic>? selectedVariant,
    bool clearVariant = false,
    Map<String, dynamic>? selectedPackage,
    bool clearPackage = false,
    int? qty,
    String? error,
    bool clearError = false,
  }) {
    return ProductState(
      schema: schema ?? this.schema,
      isLoading: isLoading ?? this.isLoading,
      selectedVariant: clearVariant
          ? null
          : (selectedVariant ?? this.selectedVariant),
      selectedPackage: clearPackage
          ? null
          : (selectedPackage ?? this.selectedPackage),
      qty: qty ?? this.qty,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProductBloc extends CubitSignal<ProductState> {
  ProductBloc() : super(initialState: const ProductState());

  Future<void> loadPostFromUrl(String url) async {
    emit(stateValue.copyWith(isLoading: true, clearError: true));

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        emit(
          stateValue.copyWith(
            isLoading: false,
            error: 'HTTP ${response.statusCode}',
          ),
        );
        return;
      }

      final service = BloggerDataService();
      final raw = service.extractJsonLd(response.body);
      if (raw == null) {
        emit(stateValue.copyWith(isLoading: false, error: 'No schema found'));
        return;
      }

      final resolved = await service.resolveAndLoadSchema(raw, base: url);

      emit(
        stateValue.copyWith(
          schema: resolved,
          isLoading: false,
          clearVariant: true,
          clearPackage: true,
          qty: 1,
        ),
      );
    } catch (e) {
      emit(stateValue.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectVariant(Map<String, dynamic>? variant) {
    if (variant == null) {
      emit(stateValue.copyWith(clearVariant: true));
    } else {
      emit(stateValue.copyWith(selectedVariant: variant));
    }
  }

  void selectPackage(Map<String, dynamic>? package) {
    if (package == null) {
      emit(stateValue.copyWith(clearPackage: true));
    } else {
      emit(stateValue.copyWith(selectedPackage: package));
    }
  }

  void setQty(int qty) {
    if (qty < 1) return;
    emit(stateValue.copyWith(qty: qty));
  }

  Future<void> addToCart(
    CartRepository repo,
    String postUrl, {
    List<CartAddon> addons = const [],
  }) async {
    final schema = stateValue.schema;
    if (schema == null) return;

    try {
      // Extract relevant fields.
      final name = _extractName(schema) ?? 'Product';
      final imageUrl = _extractImage(schema) ?? '';
      final priceStr = _extractPrice(schema) ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;
      final currency = _extractCurrency(schema) ?? 'INR';
      final postId = (schema['_postId'] as String?) ?? postUrl;
      final variantId = stateValue.selectedVariant?['@id'] as String?;

      final item = OrderItem(
        postId: postId,
        postUrl: postUrl,
        name: name,
        imageUrl: imageUrl,
        price: price,
        priceCurrency: currency,
        qty: stateValue.qty,
        variantId: variantId,
        addons: addons,
      );

      await repo.addItem(item);
    } catch (e) {
      emit(stateValue.copyWith(error: e.toString()));
    }
  }

  Future<void> addToWishlist(WishlistRepository repo, String postId) async {
    try {
      await repo.add(postId);
    } catch (e) {
      emit(stateValue.copyWith(error: e.toString()));
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static String? _extractName(Map<String, dynamic> schema) {
    final name = schema['name'];
    if (name is String) return name;
    if (name is List && name.isNotEmpty) {
      final first = name.first;
      if (first is String) return first;
      if (first is Map) return first['@value'] as String?;
    }
    return null;
  }

  static String? _extractImage(Map<String, dynamic> schema) {
    final raw = schema['image'];
    if (raw == null) return null;
    final first = raw is List ? (raw.isNotEmpty ? raw.first : null) : raw;
    if (first == null) return null;
    if (first is String) return first;
    if (first is Map) {
      return (first['url'] ?? first['contentUrl']) as String?;
    }
    return null;
  }

  static String? _extractPrice(Map<String, dynamic> schema) {
    final offers = schema['offers'];
    final offer = offers is List
        ? (offers.isNotEmpty ? offers.first : null)
        : offers;
    if (offer is Map) {
      final p = offer['price'];
      if (p != null) return p.toString();
    }
    final p = schema['price'];
    if (p != null) return p.toString();
    return null;
  }

  static String? _extractCurrency(Map<String, dynamic> schema) {
    final offers = schema['offers'];
    final offer = offers is List
        ? (offers.isNotEmpty ? offers.first : null)
        : offers;
    if (offer is Map) {
      final c = offer['priceCurrency'];
      if (c is String) return c;
    }
    final c = schema['priceCurrency'];
    if (c is String) return c;
    return null;
  }
}
