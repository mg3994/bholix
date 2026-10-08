import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/schema/schema_extractor.dart';
import '../product/widgets/stock_badge.dart';

class GridCard extends StatelessWidget {
  final Map<String, dynamic> schema;
  final String postUrl;
  final void Function(String postUrl) onTap;

  const GridCard({
    super.key,
    required this.schema,
    required this.postUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = SchemaExtractor.extractName(schema) ?? 'Product';
    final price = SchemaExtractor.extractPrice(schema);
    final currency = SchemaExtractor.extractPriceCurrency(schema) ?? '';
    final imageUrl = SchemaExtractor.extractImage(schema);
    final availability = SchemaExtractor.extractStockLevel(schema);
    final areaServed = _areaLabel(schema['areaServed']);

    return GestureDetector(
      onTap: () => onTap(postUrl),
      child: Card(
        color: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardImage(imageUrl: imageUrl),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$currency $price'.trim(),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StockBadge(availability),
                      if (areaServed != null) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Chip(
                            label: Text(
                              areaServed,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                            backgroundColor: const Color(0xFF2a2a2a),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _areaLabel(dynamic areaServed) {
    if (areaServed == null) return null;
    final areas = areaServed is List ? areaServed : [areaServed];
    if (areas.isEmpty) return null;
    final first = areas.first;
    if (first is String) return first;
    if (first is Map) {
      final name = first['name'];
      if (name is String && name.isNotEmpty) return name;
      final code = first['postalCode'];
      if (code is String && code.isNotEmpty) return code;
    }
    return null;
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;

  const _CardImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const SizedBox(
        height: 120,
        child: ColoredBox(
          color: Color(0xFF2a2a2a),
          child: Center(child: Icon(Icons.image, color: Colors.grey, size: 32)),
        ),
      );
    }

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: Color(0xFF2a2a2a),
          child: Center(child: Icon(Icons.image, color: Colors.grey, size: 32)),
        ),
        errorWidget: (context, url, error) => const ColoredBox(
          color: Color(0xFF2a2a2a),
          child: Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
          ),
        ),
      ),
    );
  }
}
