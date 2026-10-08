import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';

import '../schema/schema_extractor.dart';
import 'cart_models.dart';

export 'cart_models.dart';

/// Persists the user's cart as JSON in the app documents directory and
/// provides CRUD operations over [OrderItem]s and nested [CartAddon]s.
class CartRepository {
  static const _fileName = 'antinna_cart.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Loads the current [CartOrder] from disk.
  ///
  /// Returns [CartOrder.empty] if no file is found or it cannot be parsed.
  Future<CartOrder> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return CartOrder.empty();
      final raw = await file.readAsString();
      return CartOrder.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CartOrder.empty();
    }
  }

  Future<void> _save(CartOrder order) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(order.toJson()));
  }

  /// Adds [item] to the cart.
  ///
  /// If an item with the same [OrderItem.postId] and [OrderItem.variantId]
  /// already exists, its qty is incremented and addons are merged.
  Future<CartOrder> addItem(OrderItem item) async {
    final order = await load();
    final index = order.items.indexWhere(
      (i) => i.postId == item.postId && i.variantId == item.variantId,
    );

    late CartOrder updated;
    if (index >= 0) {
      final existing = order.items[index];

      // Merge addons: keep existing addon entries; append new ones.
      final mergedAddonNames = existing.addons.map((a) => a.name).toSet();
      final mergedAddons = [
        ...existing.addons,
        ...item.addons.where((a) => !mergedAddonNames.contains(a.name)),
      ];

      final effectiveMax = existing.maxValue != null && existing.inventoryLevel != null
          ? math.min(existing.maxValue!, existing.inventoryLevel!)
          : (existing.maxValue ?? existing.inventoryLevel);

      var newQty = existing.qty + item.qty;
      if (effectiveMax != null && newQty > effectiveMax) {
        newQty = effectiveMax;
      }

      final updatedItem = existing.copyWith(
        qty: newQty,
        addons: mergedAddons,
      );
      final newItems = List<OrderItem>.from(order.items)..[index] = updatedItem;
      updated = CartOrder(items: newItems, priceCurrency: order.priceCurrency);
    } else {
      updated = CartOrder(
        items: [...order.items, item],
        priceCurrency: order.priceCurrency,
      );
    }

    await _save(updated);
    return updated;
  }

  /// Adds a nested [addon] to a specific cart item identified by [postId] and [variantId].
  Future<CartOrder> addAddonToItem(
    String postId,
    CartAddon addon, {
    String? variantId,
  }) async {
    final order = await load();
    final newItems = order.items.map((item) {
      if (item.postId == postId && item.variantId == variantId) {
        final existingIdx = item.addons.indexWhere((a) => a.name == addon.name);
        List<CartAddon> newAddons;
        if (existingIdx >= 0) {
          final existing = item.addons[existingIdx];
          final maxLimit = item.getScaledAddonMax(existing);
          final newQty = existing.qty + addon.qty;
          final clamped = maxLimit != null ? math.min(newQty, maxLimit) : newQty;
          newAddons = List<CartAddon>.from(item.addons)
            ..[existingIdx] = existing.copyWith(qty: clamped);
        } else {
          newAddons = [...item.addons, addon];
        }
        return item.copyWith(addons: newAddons);
      }
      return item;
    }).toList();

    final updated = CartOrder(items: newItems, priceCurrency: order.priceCurrency);
    await _save(updated);
    return updated;
  }

  /// Removes the item matching [postId] (and optional [variantId]) from the cart.
  Future<CartOrder> removeItem(String postId, {String? variantId}) async {
    final order = await load();
    final newItems = order.items
        .where((i) => !(i.postId == postId && i.variantId == variantId))
        .toList();
    final updated = CartOrder(items: newItems, priceCurrency: order.priceCurrency);
    await _save(updated);
    return updated;
  }

  /// Updates the qty of the item matching [postId] / [variantId].
  /// Scales add-on limits proportionally to maintain constraints.
  /// Removes the item if [qty] is ≤ 0.
  Future<CartOrder> updateQty(
    String postId,
    int qty, {
    String? variantId,
  }) async {
    final order = await load();
    List<OrderItem> newItems;

    if (qty <= 0) {
      newItems = order.items
          .where((i) => !(i.postId == postId && i.variantId == variantId))
          .toList();
    } else {
      newItems = order.items.map((i) {
        if (i.postId == postId && i.variantId == variantId) {
          final effectiveMax = i.maxValue != null && i.inventoryLevel != null
              ? math.min(i.maxValue!, i.inventoryLevel!)
              : (i.maxValue ?? i.inventoryLevel);
          final targetQty = effectiveMax != null ? math.min(qty, effectiveMax) : qty;

          // Scale add-ons proportionally with new parent quantity
          final scaledAddons = i.addons.map((addon) {
            final maxLimit = i.copyWith(qty: targetQty).getScaledAddonMax(addon);
            final clamped = maxLimit != null ? math.min(addon.qty, maxLimit) : addon.qty;
            return addon.copyWith(qty: clamped);
          }).toList();

          return i.copyWith(qty: targetQty, addons: scaledAddons);
        }
        return i;
      }).toList();
    }

    final updated = CartOrder(items: newItems, priceCurrency: order.priceCurrency);
    await _save(updated);
    return updated;
  }

  /// Synchronizes cart items with freshly fetched Blogger post schema data.
  /// Marks deleted/draft posts as unavailable or updates availability/pricing.
  Future<CartOrder> updateItemDetails(
    int index,
    Map<String, dynamic>? freshSchema,
  ) async {
    final order = await load();
    if (index < 0 || index >= order.items.length) return order;

    final item = order.items[index];
    OrderItem updatedItem;

    if (freshSchema == null) {
      updatedItem = item.copyWith(isUnavailable: true);
    } else {
      final priceStr = SchemaExtractor.extractPrice(freshSchema);
      final priceNum = priceStr != null ? double.tryParse(priceStr) : null;
      final currency = SchemaExtractor.extractPriceCurrency(freshSchema);
      final availability = SchemaExtractor.extractAvailability(freshSchema);
      final eq = SchemaExtractor.extractEligibleQuantity(freshSchema);
      final inventoryLevel = SchemaExtractor.extractInventoryLevel(freshSchema);

      updatedItem = item.copyWith(
        isUnavailable: false,
        price: priceNum ?? item.price,
        priceCurrency: currency ?? item.priceCurrency,
        availability: availability,
        minValue: eq['minValue'] as int?,
        maxValue: eq['maxValue'] as int?,
        inventoryLevel: inventoryLevel,
      );
    }

    final newItems = List<OrderItem>.from(order.items)..[index] = updatedItem;
    final updated = CartOrder(items: newItems, priceCurrency: order.priceCurrency);
    await _save(updated);
    return updated;
  }

  /// Clears all items from the cart.
  Future<CartOrder> clear() async {
    const empty = CartOrder(items: [], priceCurrency: 'INR');
    await _save(empty);
    return empty;
  }
}
