# 04 Backend & Integrations Architecture

## Overview
This document outlines external services, backend bridges, payment processing, address/geo verification, and phone verification mechanisms in `bholix`.

---

## 1. Google Apps Script Bridge (`AppsScriptService`)

Located in `lib/core/services/apps_script_service.dart`.

Acts as a lightweight, serverless web backend bridge deployed on Google Apps Script:
* **Order Creation (`createOrder`)**: Posts cart items, user address, and payment transaction metadata to an Apps Script Web App endpoint.
* **Place Suggestions (`getPlaceSuggestions`)**: Interfaces with Google Places API via Apps Script proxy to fetch location search suggestions.

```
┌──────────────┐         POST /exec?action=createOrder         ┌──────────────────────┐
│  Mobile App  ├──────────────────────────────────────────────►│ Google Apps Script   │
│ (bholix client)│◄──────────────────────────────────────────────┤ Web App Endpoint     │
└──────────────┘           JSON Response {status: "ok"}        └──────────────────────┘
```

---

## 2. Payment Integration (`PaymentService`)

Located in `lib/core/services/payment_service.dart`.

Provides unified payment processing with special support for Indian Unified Payments Interface (UPI):

### UPI Deep Link Generator (`generateUpiUri`)
Generates standardized `upi://pay` URI strings for native UPI intent invocation:
$$\text{URI} = \text{upi://pay?pa=}\langle\text{vpa}\rangle\text{\&pn=}\langle\text{name}\rangle\text{\&mc=}\langle\text{mcc}\rangle\text{\&tr=}\langle\text{txnId}\rangle\text{\&tn=}\langle\text{note}\rangle\text{\&am=}\langle\text{amount}\rangle\text{\&cu=INR}$$

* Default VPA: `manishsharma3994@okhdfcbank`
* Merchant Category Code (MCC): `5251` (Hardware Stores / General Retail)

### Multi-Channel Payment Methods:
* **Google Pay / Apple Pay**: Configured via payment token payloads.
* **Card & Net Banking**: Handled via secure webview/gateway redirects.

---

## 3. Geo & Address Verification (`GeoVerificationService`)

Located in `lib/core/services/geo_verification_service.dart`.

* **Indian PIN Code Validation**: Validates 6-digit postal codes against regex `^[1-9][0-9]{5}$`.
* **Delivery Metadata Generation**: Transforms raw checkout form fields into Schema.org compliant structured objects (`ParcelDelivery`, `PostalAddress`, `GeoCoordinates`).

---

## 4. Phone Verification (`PhoneVerificationService`)

Located in `lib/core/services/phone_verification_service.dart`.

* **E.164 Formatting**: Parses international country calling codes (`+91`, `+1`, `+44`, etc.) and formats raw phone input into standard E.164 string format.
* **OTP Session State Machine**: Manages SMS OTP send, timeout timer, resend throttle, and code verification.

---

## 5. Pagination Manager (`PaginationManager`)

Located in `lib/core/services/pagination_manager.dart`.

Manages standard feed pagination states:
* Properties: `startIndex` (1-based), `maxResults` (default 10), `hasMore`, `isLoading`.
* Calculates nextPage parameters and prevents concurrent duplicate page requests.

---

## Portability Recommendations
* **UPI URIs**: The `upi://pay` URI spec is standard across Android/iOS in India; enforce URL encoding for merchant name and transaction note parameters.
* **Phone Formatting**: Standardize phone number parsing using Google's `libphonenumber` library equivalent in target languages.
* **JSON-LD Schema Output**: Ensure order delivery metadata strictly outputs Schema.org types (`ParcelDelivery`, `PostalAddress`).
