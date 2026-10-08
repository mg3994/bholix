import 'package:flutter/material.dart';

class StockBadge extends StatelessWidget {
  final String? availability;

  const StockBadge(this.availability, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(availability);
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(color: color),
    );
  }

  static (String, Color) _resolve(String? availability) {
    if (availability == null) {
      return ('Unknown', Colors.grey);
    }
    final lower = availability.toLowerCase();
    if (lower.contains('instock') || lower.contains('in_stock')) {
      return ('In Stock', Colors.green);
    }
    if (lower.contains('outofstock') || lower.contains('out_of_stock')) {
      return ('Out of Stock', Colors.red);
    }
    if (lower.contains('preorder') || lower.contains('pre_order')) {
      return ('Pre-Order', Colors.orange);
    }
    if (lower.contains('instock')) return ('In Stock', Colors.green);
    return ('Unknown', Colors.grey);
  }
}
