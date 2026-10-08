import 'package:flutter/material.dart';

class VariantSelector extends StatelessWidget {
  final String label;
  final List<dynamic> values;
  final String? selectedValue;
  final void Function(String) onSelect;

  const VariantSelector({
    super.key,
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: values.map<Widget>((v) {
            final str = _stringify(v);
            final isSelected = str == selectedValue;
            return ChoiceChip(
              label: Text(str),
              selected: isSelected,
              onSelected: (_) => onSelect(str),
              selectedColor: Colors.cyanAccent.withValues(alpha: 0.15),
              backgroundColor: const Color(0xFF2a2a2a),
              side: BorderSide(
                color: isSelected ? Colors.cyanAccent : Colors.grey,
                width: isSelected ? 1.5 : 0.5,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static String _stringify(dynamic v) {
    if (v is String) return v;
    if (v is Map) return (v['name'] ?? v['value'] ?? v.toString()).toString();
    return v.toString();
  }
}
