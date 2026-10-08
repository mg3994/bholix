import 'package:flutter/material.dart';

import '../../../core/schema/schema_extractor.dart';

/// Displays selectable service/product packages from `hasOfferCatalog`.
class PackageSelector extends StatelessWidget {
  final List<Map<String, dynamic>> packages;
  final Map<String, dynamic>? selected;
  final void Function(Map<String, dynamic>) onSelect;

  const PackageSelector({
    super.key,
    required this.packages,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Packages',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packages.map((pkg) {
            final item = pkg['itemOffered'];
            final name = (item is Map)
                ? (SchemaExtractor.getLocalizedValue(
                        item['name'], SchemaExtractor.currentLocale) ??
                    '')
                : SchemaExtractor.getLocalizedValue(
                        pkg['name'], SchemaExtractor.currentLocale) ??
                    '';
            final price = pkg['price']?.toString() ?? '';
            final currency = (pkg['priceCurrency'] as String?) ?? '';
            final isSelected = selected != null &&
                (selected!['name'] == pkg['name'] ||
                    selected == pkg);

            return GestureDetector(
              onTap: () => onSelect(pkg),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyanAccent.withValues(alpha: 0.15)
                      : const Color(0xFF2a2a2a),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.cyanAccent
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.cyanAccent
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$currency $price'.trim(),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
