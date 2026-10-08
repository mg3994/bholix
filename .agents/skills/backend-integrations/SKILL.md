---
name: backend-integrations
version: 1
description: Spec and guide for external backend integrations, Google Apps Script bridge, UPI deep link payment generation, address geo-verification, and phone number formatting.
---

# Backend Integrations & Services Skill

Use this skill whenever working with, modifying, or porting backend services, payment processors, address validation, or phone verification.

## Core Services
- `lib/core/services/apps_script_service.dart`: Google Apps Script web app endpoint bridge for order creation and Google Places suggestions.
- `lib/core/services/payment_service.dart`: Google Pay, Apple Pay, card payments, and UPI deep link generation (`manishsharma3994@okhdfcbank`, MCC `5251`).
- `lib/core/services/geo_verification_service.dart`: Indian PIN code validation (`^[1-9][0-9]{5}$`) and Schema.org `ParcelDelivery` generator.
- `lib/core/services/phone_verification_service.dart`: E.164 phone formatting (`+91XXXXXXXXXX`) and OTP verification workflow.
- `lib/core/services/pagination_manager.dart`: Feed pagination state management.

## Fundamental Rules
1. **UPI URI Formatting**:
   Ensure `vpa`, `name`, `mcc`, `txnId`, `note`, and `amount` (2 decimal places) are properly URL-encoded into `upi://pay?...`.
2. **Delivery Metadata**:
   Export delivery address information using standardized Schema.org `ParcelDelivery` and `PostalAddress` maps.

## Documentation References
- Detailed Specification: `docs/03_services_and_api_spec.md`
- System Architecture: `arch/04_backend_and_integrations.md`
- Porting Prompts: `prompts/03_services_porting_prompts.md`
