import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'cart_models.dart';

export 'cart_models.dart';

/// Persists the user's cart as JSON in the app documents directory and
/// provides CRUD operations over [OrderItem]s.
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
  /// already exists, its qty is incremented and addons are merged (unique by
  /// name, first occurrence wins for price).
  Future<CartOrder> addItem(OrderItem item) async {
    final order = await load();
    final index = order.items.indexWhere(
      (i) => i.postId == item.postId && i.variantId == item.variantId,
    );

    late CartOrder updated;
    if (index >= 0) {
      final existing = order.items[index];

      // Merge addons: keep existing addon entries; append new ones.
      final mergedAddonNames =
          existing.addons.map((a) => a.name).toSet();
      final mergedAddons = [
        ...existing.addons,
        ...item.addons.where((a) => !mergedAddonNames.contains(a.name)),
      ];

      final updatedItem = existing.copyWith(
        qty: existing.qty + item.qty,
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

  /// Removes the item matching [postId] (and optional [variantId]) from the
  /// cart.
  Future<CartOrder> removeItem(String postId, {String? variantId}) async {
    final order = await load();
    final newItems = order.items
        .where(
          (i) => !(i.postId == postId && i.variantId == variantId),
        )
        .toList();
    final updated =
        CartOrder(items: newItems, priceCurrency: order.priceCurrency);
    await _save(updated);
    return updated;
  }

  /// Updates the qty of the item matching [postId] / [variantId].
  ///
  /// Removes the item if [qty] is ≤ 0.
  Future<CartOrder> updateQty(String postId, int qty,
      {String? variantId}) async {
    final order = await load();
    List<OrderItem> newItems;

    if (qty <= 0) {
      newItems = order.items
          .where(
            (i) => !(i.postId == postId && i.variantId == variantId),
          )
          .toList();
    } else {
      newItems = order.items.map((i) {
        if (i.postId == postId && i.variantId == variantId) {
          return i.copyWith(qty: qty);
        }
        return i;
      }).toList();
    }

    final updated =
        CartOrder(items: newItems, priceCurrency: order.priceCurrency);
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
