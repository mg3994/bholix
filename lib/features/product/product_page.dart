import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/cart/cart_provider.dart';
import '../../core/cart/cart_repository.dart';
import '../../core/schema/schema_extractor.dart';
import '../../core/wishlist/wishlist_repository.dart';
import 'product_bloc.dart';
import 'widgets/addon_section.dart';
import 'widgets/image_carousel.dart';
import 'widgets/package_selector.dart';
import 'widgets/seller_card.dart';
import 'widgets/specs_section.dart';
import 'widgets/stock_badge.dart';
import 'widgets/variant_selector.dart';

class ProductPage extends StatefulWidget {
  final String postUrl;

  const ProductPage({super.key, required this.postUrl});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late final ProductBloc _bloc;
  final Set<String> _selectedAddons = {};

  @override
  void initState() {
    super.initState();
    _bloc = ProductBloc();
    _bloc.loadPostFromUrl(widget.postUrl);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Product', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocSignalBuilder<ProductBloc, ProductState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }
          if (state.error != null) {
            return Center(
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (state.schema == null) {
            return const Center(
              child: Text(
                'No product data',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return _ProductBody(
            schema: state.schema!,
            state: state,
            bloc: _bloc,
            postUrl: widget.postUrl,
            selectedAddons: _selectedAddons,
            onAddonToggle: (name, checked) {
              setState(() {
                if (checked) {
                  _selectedAddons.add(name);
                } else {
                  _selectedAddons.remove(name);
                }
              });
            },
          );
        },
      ),
    );
  }
}

class _ProductBody extends StatelessWidget {
  final Map<String, dynamic> schema;
  final ProductState state;
  final ProductBloc bloc;
  final String postUrl;
  final Set<String> selectedAddons;
  final void Function(String name, bool checked) onAddonToggle;

  const _ProductBody({
    required this.schema,
    required this.state,
    required this.bloc,
    required this.postUrl,
    required this.selectedAddons,
    required this.onAddonToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = SchemaExtractor.extractName(schema) ?? 'Product';
    final description = SchemaExtractor.extractDescription(schema);
    final price = SchemaExtractor.extractPrice(schema);
    final currency = SchemaExtractor.extractPriceCurrency(schema) ?? '';
    final images = SchemaExtractor.extractImages(schema);
    final availability = SchemaExtractor.extractStockLevel(schema);
    final variants = SchemaExtractor.extractVariants(schema);
    final packages = SchemaExtractor.extractPackages(schema);
    final addons = SchemaExtractor.extractAddons(schema);
    final seller = SchemaExtractor.extractSeller(schema);
    final properties = SchemaExtractor.extractAdditionalProperties(schema);
    final variesBy = _variesByKeys(variants);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImageCarousel(images),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (price != null)
                      Text(
                        '$currency $price'.trim(),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(width: 12),
                    StockBadge(availability),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
                // Variant selectors
                if (variants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...variesBy.map((key) {
                    final values = _valuesForKey(variants, key);
                    final selected = _selectedVariantValue(state, key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VariantSelector(
                        label: key,
                        values: values,
                        selectedValue: selected,
                        onSelect: (val) =>
                            _selectVariantByKey(bloc, variants, key, val),
                      ),
                    );
                  }),
                ],
                // Package selector (hasOfferCatalog)
                if (packages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PackageSelector(
                    packages: packages,
                    selected: state.selectedPackage,
                    onSelect: bloc.selectPackage,
                  ),
                ],
                // Add-ons
                if (addons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AddonSection(
                    addons: addons,
                    selected: selectedAddons,
                    onToggle: onAddonToggle,
                  ),
                ],
                // Qty stepper
                const SizedBox(height: 16),
                _QtyStepper(bloc: bloc, qty: state.qty),
                // Action buttons
                const SizedBox(height: 16),
                _ActionButtons(bloc: bloc, postUrl: postUrl, schema: schema),
                // Seller
                if (seller != null) ...[
                  const SizedBox(height: 16),
                  SellerCard(seller),
                ],
                // Specs
                if (properties.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SpecsSection(properties),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<String> _variesByKeys(List<Map<String, dynamic>> variants) {
    final keys = <String>{};
    for (final v in variants) {
      v.forEach((k, _) {
        if (!k.startsWith('@') && k != 'name' && k != 'description') {
          keys.add(k);
        }
      });
    }
    // prefer common keys
    if (variants.isNotEmpty) {
      final first = variants.first;
      // Common product variant keys
      for (final key in ['size', 'color', 'flavor', 'style', 'material']) {
        if (first.containsKey(key)) keys.add(key);
      }
    }
    // Fallback: use 'name' from variant maps
    if (keys.isEmpty && variants.isNotEmpty) return ['name'];
    return keys.toList();
  }

  static List<dynamic> _valuesForKey(
    List<Map<String, dynamic>> variants,
    String key,
  ) {
    if (key == 'name') return variants.map((v) => v['name'] ?? v).toList();
    return variants.map((v) => v[key]).where((v) => v != null).toList();
  }

  static String? _selectedVariantValue(ProductState state, String key) {
    final v = state.selectedVariant;
    if (v == null) return null;
    if (key == 'name') {
      final n = v['name'];
      if (n is String) return n;
    }
    final val = v[key];
    if (val is String) return val;
    return null;
  }

  static void _selectVariantByKey(
    ProductBloc bloc,
    List<Map<String, dynamic>> variants,
    String key,
    String val,
  ) {
    final match = variants.firstWhere((v) {
      if (key == 'name') return v['name']?.toString() == val;
      return v[key]?.toString() == val;
    }, orElse: () => {});
    if (match.isEmpty) return;
    bloc.selectVariant(match);
  }
}

class _QtyStepper extends StatelessWidget {
  final ProductBloc bloc;
  final int qty;

  const _QtyStepper({required this.bloc, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Qty:', style: TextStyle(color: Colors.white70)),
        const SizedBox(width: 12),
        _StepBtn(icon: Icons.remove, onTap: () => bloc.setQty(qty - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$qty',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _StepBtn(icon: Icons.add, onTap: () => bloc.setQty(qty + 1)),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 18, color: Colors.cyanAccent),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ProductBloc bloc;
  final String postUrl;
  final Map<String, dynamic> schema;

  const _ActionButtons({
    required this.bloc,
    required this.postUrl,
    required this.schema,
  });

  @override
  Widget build(BuildContext context) {
    final postId = (schema['_postId'] as String?) ?? postUrl;
    final cartBloc = CartProvider.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await bloc.addToCart(CartRepository(), postUrl);
              // Reload shared cart so badge updates.
              await cartBloc.loadCart();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to cart'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.favorite_border),
            label: const Text('Wishlist'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await bloc.addToWishlist(WishlistRepository(), postId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to wishlist'),
                    backgroundColor: Color(0xFF1a1a1a),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
