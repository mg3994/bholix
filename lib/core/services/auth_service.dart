import 'apps_script_service.dart';

/// User session model mirroring Antinna AuthEngine state.
class UserSession {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? idToken;
  final String? deviceToken;
  final bool hasPhoneLinked;

  const UserSession({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.idToken,
    this.deviceToken,
    this.hasPhoneLinked = false,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (idToken != null) 'idToken': idToken,
        if (deviceToken != null) 'deviceToken': deviceToken,
        'hasPhoneLinked': hasPhoneLinked,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      idToken: json['idToken'] as String?,
      deviceToken: json['deviceToken'] as String?,
      hasPhoneLinked: json['hasPhoneLinked'] as bool? ?? false,
    );
  }
}

/// Service porting Antinna AuthEngine (`auth-engine.js`) for session management,
/// Firebase Auth state simulation, and device token syncing with AppsScript.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService getInstance() => _instance;

  UserSession? _currentUser;
  final AppsScriptService _appsScriptService = AppsScriptService.getInstance();

  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Simulates Google Sign-In and syncs device session with backend Apps Script.
  Future<UserSession> signInWithGoogle({
    String? customUid,
    String? email,
    String? displayName,
    String? idToken,
    String? deviceToken,
  }) async {
    final session = UserSession(
      uid: customUid ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email ?? 'user@example.com',
      displayName: displayName ?? 'Antinna User',
      idToken: idToken ?? 'mock_firebase_id_token_${DateTime.now().millisecondsSinceEpoch}',
      deviceToken: deviceToken,
      hasPhoneLinked: false,
    );

    _currentUser = session;

    // Sync device session with backend Apps Script
    try {
      await _appsScriptService.callAction(
        'SYNC_DEVICE',
        payload: session.toJson(),
        authToken: session.idToken,
      );
    } catch (_) {
      // Non-blocking sync failure
    }

    return session;
  }

  /// Links phone number verification status to current session.
  Future<UserSession?> linkPhoneNumber(String phoneNumber) async {
    if (_currentUser == null) return null;
    _currentUser = UserSession(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      photoUrl: _currentUser!.photoUrl,
      idToken: _currentUser!.idToken,
      deviceToken: _currentUser!.deviceToken,
      hasPhoneLinked: true,
    );
    return _currentUser;
  }

  /// Signs out user and notifies backend.
  Future<void> signOut() async {
    if (_currentUser != null) {
      try {
        await _appsScriptService.callAction(
          'LOGOUT_DEVICE',
          payload: {'uid': _currentUser!.uid},
          authToken: _currentUser!.idToken,
        );
      } catch (_) {}
    }
    _currentUser = null;
  }
}
