import 'package:flutter/material.dart';

import 'cart_repository.dart';
import '../../features/cart/cart_bloc.dart';

/// App-level cart singleton. Wrap above [MaterialApp.router] so all routes
/// share the same [CartBloc] instance.
class CartProvider extends InheritedWidget {
  final CartBloc bloc;

  const CartProvider({
    super.key,
    required this.bloc,
    required super.child,
  });

  static CartBloc of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<CartProvider>();
    assert(provider != null, 'No CartProvider found in widget tree');
    return provider!.bloc;
  }

  @override
  bool updateShouldNotify(CartProvider oldWidget) => bloc != oldWidget.bloc;
}

/// Manages the lifecycle of the singleton [CartBloc].
class CartProviderRoot extends StatefulWidget {
  final Widget child;

  const CartProviderRoot({super.key, required this.child});

  @override
  State<CartProviderRoot> createState() => _CartProviderRootState();
}

class _CartProviderRootState extends State<CartProviderRoot> {
  late final CartBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CartBloc(CartRepository());
    _bloc.loadCart();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CartProvider(bloc: _bloc, child: widget.child);
  }
}
