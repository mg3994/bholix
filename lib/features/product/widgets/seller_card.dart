import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SellerCard extends StatelessWidget {
  final Map<String, dynamic>? seller;

  const SellerCard(this.seller, {super.key});

  @override
  Widget build(BuildContext context) {
    if (seller == null) return const SizedBox.shrink();

    final name = _str(seller!['name']);
    final phone = _str(seller!['telephone']);
    final email = _str(seller!['email']);
    final address = _addressStr(seller!['address']);

    if (name == null && phone == null && email == null && address == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFF1a1a1a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seller',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.cyanAccent,
              ),
            ),
            if (name != null) ...[
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (phone != null) ...[
              const SizedBox(height: 4),
              _ContactRow(icon: Icons.phone, text: phone, context: context),
            ],
            if (email != null) ...[
              const SizedBox(height: 4),
              _ContactRow(icon: Icons.email, text: email, context: context),
            ],
            if (address != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _str(dynamic val) {
    if (val is String) return val.isEmpty ? null : val;
    return null;
  }

  static String? _addressStr(dynamic addr) {
    if (addr == null) return null;
    if (addr is String) return addr.isEmpty ? null : addr;
    if (addr is Map) {
      final parts = <String>[];
      for (final key in [
        'streetAddress',
        'addressLocality',
        'addressRegion',
        'postalCode',
        'addressCountry',
      ]) {
        final v = addr[key];
        if (v is String && v.isNotEmpty) parts.add(v);
      }
      if (parts.isEmpty) return null;
      return parts.join(', ');
    }
    return null;
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final BuildContext context;

  const _ContactRow({
    required this.icon,
    required this.text,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Copied: $text')));
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.cyanAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
