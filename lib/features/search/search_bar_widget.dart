import 'package:flutter/material.dart';

/// A search bar that parses free-text input.
///
/// Recognises `label:X` tokens as labels and treats the remainder as keywords.
/// On submit, calls [onSearch] with the separated lists.
class SearchBarWidget extends StatefulWidget {
  final void Function(List<String> keywords, List<String> labels) onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  final List<String> _activeLabels = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final parts = raw.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final labels = <String>[];
    final keywords = <String>[];

    for (final part in parts) {
      if (part.startsWith('label:')) {
        final lbl = part.substring(6).trim();
        if (lbl.isNotEmpty) labels.add(lbl);
      } else {
        keywords.add(part);
      }
    }

    setState(() {
      _activeLabels
        ..clear()
        ..addAll(labels);
    });

    widget.onSearch(keywords, labels);
  }

  void _removeLabel(String label) {
    setState(() => _activeLabels.remove(label));
    widget.onSearch([], List<String>.from(_activeLabels));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search or label:electronics',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send, color: Colors.cyanAccent),
              onPressed: () => _submit(_controller.text),
            ),
            filled: true,
            fillColor: const Color(0xFF1a1a1a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          onSubmitted: _submit,
        ),
        if (_activeLabels.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _activeLabels.map((lbl) {
              return Chip(
                label: Text(lbl,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 12)),
                backgroundColor: Colors.cyanAccent,
                deleteIconColor: Colors.black54,
                onDeleted: () => _removeLabel(lbl),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
