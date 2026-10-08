import 'package:flutter_test/flutter_test.dart';
import 'package:bholix/core/services/phone_verification_service.dart';
import 'package:bholix/core/services/auth_service.dart';

void main() {
  group('PhoneVerificationService', () {
    test('validatePhoneNumber validates 10-digit numbers for +91 and +1', () {
      final service = PhoneVerificationService();
      expect(service.validatePhoneNumber('+91', '9876543210'), isTrue);
      expect(service.validatePhoneNumber('+91', '98765'), isFalse);
      expect(service.validatePhoneNumber('+1', '5551234567'), isTrue);
    });

    test('validateOtp validates 6-digit numeric OTP', () {
      final service = PhoneVerificationService();
      expect(service.validateOtp('123456'), isTrue);
      expect(service.validateOtp('12345'), isFalse);
      expect(service.validateOtp('abcdef'), isFalse);
    });

    test('verifyOtpAndLink links phone to active auth session', () async {
      final auth = AuthService.getInstance();
      await auth.signInWithGoogle(email: 'phone_test@example.com');

      final service = PhoneVerificationService();
      final res = await service.verifyOtpAndLink('654321');

      expect(res.success, isTrue);
      expect(res.updatedSession?.hasPhoneLinked, isTrue);

      await auth.signOut();
    });
  });
}
