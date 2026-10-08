# Services Porting Prompts

Use these exact prompt templates when instructing an AI assistant to port the `bholix` backend integrations, UPI URI generators, geo-verification, and phone parsing services to another programming language or tech stack.

---

## Prompt 1: Porting Google Apps Script Service

```text
Task: Port the AppsScriptService bridge to [TARGET_LANGUAGE].

Requirements:
1. Implement createOrder(cartItems, address, payment, endpointUrl) -> Promise/Future<OrderResult>:
   - Issue HTTP POST request to endpointUrl with query parameter ?action=createOrder.
   - Send JSON payload containing serialized cartItems, address, and payment information.
2. Implement getPlaceSuggestions(query, endpointUrl) -> Promise/Future<List<PlaceSuggestion>>:
   - Issue HTTP GET request to endpointUrl with query parameter ?action=places&input={urlEncoded(query)}.
   - Parse JSON response list of place predictions.

Reference Specifications:
- docs/03_services_and_api_spec.md
- lib/core/services/apps_script_service.dart
```

---

## Prompt 2: Porting UPI Deep Link Generator

```text
Task: Port the UPI payment URI generator function to [TARGET_LANGUAGE].

Requirements:
1. Implement function generateUpiUri(vpa, name, mcc, txnId, note, amount) -> String:
   - Default VPA: "manishsharma3994@okhdfcbank"
   - Default Name: "Bholix Retail"
   - Default MCC: "5251"
   - Format amount to exactly 2 decimal places (e.g. 499.00).
   - URL encode name and note parameters.
   - Return string formatted as: upi://pay?pa={vpa}&pn={encodedName}&mc={mcc}&tr={txnId}&tn={encodedNote}&am={amount}&cu=INR

Reference Specifications:
- docs/03_services_and_api_spec.md
- lib/core/services/payment_service.dart
```

---

## Prompt 3: Porting Geo & Phone Verification

```text
Task: Port GeoVerificationService and PhoneVerificationService to [TARGET_LANGUAGE].

Requirements:
1. Indian PIN Code Validation: validate string against regex ^[1-9][0-9]{5}$.
2. Schema.org Delivery Metadata: create function buildParcelDeliverySchema(address, geoCoords) returning Schema.org ParcelDelivery JSON map.
3. E.164 Phone Formatting: format raw phone inputs into standard E.164 strings (+91XXXXXXXXXX).

Reference Specifications:
- docs/03_services_and_api_spec.md
- lib/core/services/geo_verification_service.dart
- lib/core/services/phone_verification_service.dart
```
