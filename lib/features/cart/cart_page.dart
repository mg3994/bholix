import 'package:flutter/material.dart';

import '../../core/cart/cart_repository.dart';
import 'cart_bloc.dart';
import 'cart_sheet.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Cart', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CartSheet(bloc: _bloc),
    );
  }
}
