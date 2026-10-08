/// Toast notification type matching Antinna UIManager.
enum ToastType { success, error, info }

/// Toast message model.
class ToastMessage {
  final String message;
  final ToastType type;
  final DateTime timestamp;

  ToastMessage({
    required this.message,
    this.type = ToastType.success,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Utility class porting Antinna UIManager feedback states and toast notification logic.
class UiUtils {
  static final List<ToastMessage> _toastHistory = [];

  /// Records a toast message (useful for testing UI feedback flow).
  static ToastMessage showToast(String message, [ToastType type = ToastType.success]) {
    final toast = ToastMessage(message: message, type: type);
    _toastHistory.add(toast);
    return toast;
  }

  /// Returns recent toast history.
  static List<ToastMessage> get toastHistory => List.unmodifiable(_toastHistory);

  /// Clears toast history.
  static void clearToastHistory() {
    _toastHistory.clear();
  }
}
