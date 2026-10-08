import 'package:flutter/material.dart';

class SpecsSection extends StatelessWidget {
  final List<Map<String, dynamic>> properties;

  const SpecsSection(this.properties, {super.key});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...properties.map((prop) => _SpecRow(prop)),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final Map<String, dynamic> prop;

  const _SpecRow(this.prop);

  @override
  Widget build(BuildContext context) {
    final name = _str(prop['name']) ?? prop['propertyID']?.toString() ?? '';
    final value = _str(prop['value']) ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static String? _str(dynamic v) {
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map) return v['@value'] as String?;
    if (v != null) return v.toString();
    return null;
  }
}
