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
