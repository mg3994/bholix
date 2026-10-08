import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'cart_bloc.dart';

class CartItemTile extends StatelessWidget {
  final OrderItem item;
  final CartBloc bloc;

  const CartItemTile({super.key, required this.item, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1a1a1a),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _Thumbnail(imageUrl: item.imageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.priceCurrency} ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                    ),
                  ),
                  if (item.variantId != null)
                    Text(
                      'Variant: ${item.variantId}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                _QtyControls(item: item, bloc: bloc),
                const SizedBox(height: 4),
                _DeleteButton(item: item, bloc: bloc),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String imageUrl;

  const _Thumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        height: 60,
        child: imageUrl.isEmpty
            ? const ColoredBox(
                color: Color(0xFF2a2a2a),
                child: Icon(Icons.image, color: Colors.grey),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const ColoredBox(color: Color(0xFF2a2a2a)),
                errorWidget: (context, url, error) =>
                    const ColoredBox(color: Color(0xFF2a2a2a)),
              ),
      ),
    );
  }
}

class _QtyControls extends StatelessWidget {
  final OrderItem item;
  final CartBloc bloc;

  const _QtyControls({required this.item, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallIconButton(
          icon: Icons.remove,
          onTap: () => bloc.updateQty(
            item.postId,
            item.qty - 1,
            variantId: item.variantId,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${item.qty}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _SmallIconButton(
          icon: Icons.add,
          onTap: () => bloc.updateQty(
            item.postId,
            item.qty + 1,
            variantId: item.variantId,
          ),
        ),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.cyanAccent),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final OrderItem item;
  final CartBloc bloc;

  const _DeleteButton({required this.item, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => bloc.removeItem(item.postId, variantId: item.variantId),
      child: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
    );
  }
}
