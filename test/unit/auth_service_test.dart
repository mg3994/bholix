import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('singleton instance returns same object', () {
      final a1 = AuthService.getInstance();
      final a2 = AuthService.getInstance();
      expect(identical(a1, a2), isTrue);
    });

    test('signInWithGoogle initializes session and sets isLoggedIn to true', () async {
      final auth = AuthService.getInstance();
      expect(auth.isLoggedIn, isFalse);

      final session = await auth.signInWithGoogle(
        email: 'test@example.com',
        displayName: 'Test User',
      );

      expect(session.email, 'test@example.com');
      expect(session.displayName, 'Test User');
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.uid, session.uid);

      await auth.signOut();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('linkPhoneNumber updates user session state', () async {
      final auth = AuthService.getInstance();
      await auth.signInWithGoogle(email: 'phone@example.com');
      expect(auth.currentUser?.hasPhoneLinked, isFalse);

      await auth.linkPhoneNumber('+919876543210');
      expect(auth.currentUser?.hasPhoneLinked, isTrue);

      await auth.signOut();
    });
  });
}
