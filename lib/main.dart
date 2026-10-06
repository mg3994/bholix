import 'dart:async' show runZonedGuarded;

import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';

import 'core/errors/reporter_impl.dart' show BootstrapErrorReporter;

void main() {
  const errors = BootstrapErrorReporter.active();

  FlutterError.onError = (details) {
    errors.report(details.exception, details.stack ?? StackTrace.current);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    errors.report(error, stackTrace);
    return true;
  };
  runZonedGuarded(() => runApp(const BootStrap(errors: errors)), errors.report);
}

class BootStrap extends StatefulWidget {
  final BootstrapErrorReporter errors;
  const BootStrap({super.key, required this.errors});

  @override
  State<BootStrap> createState() => _BootStrapState();
}

class _BootStrapState extends State<BootStrap> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Bootstrapped'))),
    );
  }
}
