import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:flutter/material.dart';

import 'cart_bloc.dart';
import 'cart_item_tile.dart';

class CartSheet extends StatelessWidget {
  final CartBloc bloc;

  const CartSheet({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocSignalBuilder<CartBloc, CartOrder>(
      bloc: bloc,
      builder: (context, order) {
        if (order.items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 64, color: Colors.white24),
                SizedBox(height: 12),
                Text(
                  'Your cart is empty',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) => CartItemTile(
                  item: order.items[index],
                  bloc: bloc,
                ),
              ),
            ),
            _TotalBar(order: order, bloc: bloc),
          ],
        );
      },
    );
  }
}

class _TotalBar extends StatelessWidget {
  final CartOrder order;
  final CartBloc bloc;

  const _TotalBar({required this.order, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        border: Border(top: BorderSide(color: Color(0xFF2a2a2a))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '${order.priceCurrency} ${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => bloc.clearCart(),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
            child: const Text(
              'Checkout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
