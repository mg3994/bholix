import 'package:flutter/material.dart';

class AddonSection extends StatelessWidget {
  final List<Map<String, dynamic>> addons;
  final Set<String> selected;
  final void Function(String name, bool checked) onToggle;

  const AddonSection({
    super.key,
    required this.addons,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (addons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add-ons',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        ...addons.map((addon) {
          final name = _name(addon);
          final price = _price(addon);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(name, style: const TextStyle(color: Colors.white)),
            subtitle: price != null
                ? Text(
                    price,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                    ),
                  )
                : null,
            value: selected.contains(name),
            activeColor: Colors.cyanAccent,
            checkColor: Colors.black,
            onChanged: (v) => onToggle(name, v ?? false),
          );
        }),
      ],
    );
  }

  static String _name(Map<String, dynamic> addon) {
    final n = addon['name'];
    if (n is String) return n;
    return addon.toString();
  }

  static String? _price(Map<String, dynamic> addon) {
    final offers = addon['offers'];
    final offer =
        offers is List ? (offers.isNotEmpty ? offers.first : null) : offers;
    if (offer is Map) {
      final p = offer['price'];
      if (p != null) {
        final c = offer['priceCurrency'] ?? '';
        return '$p $c'.trim();
      }
    }
    final p = addon['price'];
    if (p != null) return p.toString();
    return null;
  }
}
