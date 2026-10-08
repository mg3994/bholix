import 'package:flutter/material.dart';

import '../../core/services/location_service.dart';
import 'location_bloc.dart';
import 'location_picker_sheet.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final LocationBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = LocationBloc(LocationService());
    _bloc.loadSaved();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f0f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Set Location',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LocationPickerSheet(bloc: _bloc),
    );
  }
}
