import 'package:bloc_signals/bloc_signals.dart';

import '../../core/cart/cart_repository.dart';

export '../../core/cart/cart_models.dart';

class CartBloc extends CubitSignal<CartOrder> {
  final CartRepository repo;

  CartBloc(this.repo) : super(initialState: CartOrder.empty());

  Future<void> loadCart() async {
    final order = await repo.load();
    emit(order);
  }

  Future<void> addItem(OrderItem item) async {
    final updated = await repo.addItem(item);
    emit(updated);
  }

  Future<void> removeItem(String postId, {String? variantId}) async {
    final updated = await repo.removeItem(postId, variantId: variantId);
    emit(updated);
  }

  Future<void> updateQty(String postId, int qty, {String? variantId}) async {
    final updated = await repo.updateQty(postId, qty, variantId: variantId);
    emit(updated);
  }

  Future<void> clearCart() async {
    final updated = await repo.clear();
    emit(updated);
  }
}
