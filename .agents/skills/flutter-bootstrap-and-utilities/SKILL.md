---
name: flutter-bootstrap-and-utilities
description: "Provides standard architecture templates including robust zone-guarded bootstrap error reporting (`BootstrapErrorReporter`), high-performance O(N) cached sorting utilities (`SchwartzianSortExtension`), and app entrypoint setup (`main.dart`)."
---

# Flutter Bootstrap & Core Utilities Skill

Use this skill when implementing robust error reporting, zone guarding, high-performance cached collection sorting, and app entrypoints.

## 1. Bootstrap Error Reporter (`lib/core/errors/reporter_impl.dart`)

```dart
typedef ErrorReporter = void Function(Object error, StackTrace stackTrace);

abstract class BootstrapErrorReporter {
  const BootstrapErrorReporter();

  const factory BootstrapErrorReporter.noop() = _NoOpBootstrapErrorReporter;
  const factory BootstrapErrorReporter.active() = _ActiveBootstrapErrorReporter;

  void report(Object error, StackTrace stackTrace);
  void attach(ErrorReporter reporter);
  void close();
}

class _NoOpBootstrapErrorReporter extends BootstrapErrorReporter {
  const _NoOpBootstrapErrorReporter();

  @override
  void report(Object error, StackTrace stackTrace) {}
  @override
  void attach(ErrorReporter reporter) {}
  @override
  void close() {}
}

class _ActiveBootstrapErrorReporter extends BootstrapErrorReporter {
  // Static state allows the constructor to be const
  const _ActiveBootstrapErrorReporter();

  static ErrorReporter? _reporter;
  static bool _closed = false;
  static final List<_PendingError> _pending = [];

  @override
  void report(Object error, StackTrace stackTrace) {
    if (_closed) return;

    final reporter = _reporter;
    if (reporter == null) {
      _pending.add(_PendingError(error: error, stackTrace: stackTrace));
      return;
    }

    reporter(error, stackTrace);
  }

  @override
  void attach(ErrorReporter reporter) {
    if (_closed) throw StateError('Error reporter is closed.');
    if (_reporter != null) {
      throw StateError('Error reporter is already attached.');
    }

    _reporter = reporter;

    final pending = List<_PendingError>.of(_pending);
    _pending.clear();

    for (final error in pending) {
      reporter(error.error, error.stackTrace);
    }
  }

  @override
  void close() {
    _closed = true;
    _reporter = null;
    _pending.clear();
  }
}

final class _PendingError {
  final Object error;
  final StackTrace stackTrace;

  const _PendingError({required this.error, required this.stackTrace});
}
```

## 2. High-Performance Cached Sorting (`SchwartzianSortExtension`)

> [!TIP]
> **Performance Optimization:** Uses the Schwartzian Transform (Decorate-Sort-Undecorate) with lightweight Dart 3 records to cache expensive key computations. This guarantees that `keyOf` is invoked **exactly once** per element ($O(N)$ calls), avoiding redundant re-computations during comparisons ($O(N \log N)$).

```dart
extension SchwartzianSortExtension<T> on Iterable<T> {
  /// Sorts elements by an expensive key using the Schwartzian Transform
  /// (Decorate-Sort-Undecorate).
  ///
  /// Guarantees that [keyOf] is invoked **exactly once** per element (O(N) calls),
  /// caching the derived keys in lightweight Dart 3 records during sorting.
  List<T> sortedByExpensive<K extends Comparable<K>>(K Function(T item) keyOf) {
    final boxed = [for (final item in this) (key: keyOf(item), item: item)]
      ..sort((a, b) => a.key.compareTo(b.key));

    return [for (final entry in boxed) entry.item];
  }

  /// Sorts elements by an expensive key using a custom [compare] function.
  List<T> sortedByCompareExpensive<K>(
    K Function(T item) keyOf,
    int Function(K a, K b) compare,
  ) {
    final boxed = [for (final item in this) (key: keyOf(item), item: item)]
      ..sort((a, b) => compare(a.key, b.key));

    return [for (final entry in boxed) entry.item];
  }
}
```

## 3. App Entrypoint & Bootstrap (`lib/main.dart`)

```dart
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
      home: Scaffold(
        body: Center(child: Text('Bootstrapped')),
      ),
    );
  }
}
```
