import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/location_service.dart';
import '../location/location_bloc.dart';

class LocationPickerSheet extends StatefulWidget {
  final LocationBloc bloc;

  const LocationPickerSheet({super.key, required this.bloc});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<LocationData> _results = [];
  bool _searching = false;

  LocationService get _service => widget.bloc.service;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results = await _service.searchLocation(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    });
  }

  Future<void> _selectLocation(LocationData loc) async {
    await widget.bloc.setManual(loc);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _requestGps() async {
    await widget.bloc.requestGps();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _SearchField(
          controller: _controller,
          onChanged: _onQueryChanged,
          onGps: _requestGps,
        ),
        const SizedBox(height: 8),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final loc = _results[i];
                return ListTile(
                  leading: const Icon(Icons.location_on,
                      color: Colors.cyanAccent, size: 20),
                  title: Text(
                    _label(loc),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    loc.country,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () => _selectLocation(loc),
                );
              },
            ),
          ),
      ],
    );
  }

  static String _label(LocationData loc) {
    final parts = <String>[];
    if (loc.city.isNotEmpty) parts.add(loc.city);
    if (loc.state.isNotEmpty) parts.add(loc.state);
    if (loc.pin.isNotEmpty) parts.add(loc.pin);
    return parts.isNotEmpty ? parts.join(', ') : loc.lat;
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onGps;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onGps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search city or PIN',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          suffixIcon: IconButton(
            icon: const Icon(Icons.gps_fixed, color: Colors.cyanAccent),
            tooltip: 'Use GPS',
            onPressed: onGps,
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
        onChanged: onChanged,
      ),
    );
  }
}
