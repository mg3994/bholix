# Antinna Engine Flutter Port Summary

This document summarizes the porting of the Antinna Engine (`stable_backups_ecomm` branch `feature-product-addons-nesting-11519257417489173272`) to Flutter with enhancements for `@base`, `@id` merging, and `@language` localization.

## Core Architecture & Ported Modules

1. **Schema Engine & JSON-LD Compliance**
   - **`@base` Support**: Automatic extraction of `@base` from root schemas and `@context` for relative `@id` and URL resolution (`SchemaOverride.extractBase`).
   - **`@id` Merging**: Recursive deep-merging (`SchemaOverride.deepMerge`) when multiple nodes share the same `@id` in `@graph` documents (`BloggerDataService.toGraphDocument`).
   - **`@language` Localization**: Multilingual string resolution supporting `@language` tags, default language fallbacks, and preferred UI locales (`SchemaExtractor.getLocalizedValue`).

2. **Cart & Product Add-ons Nesting**
   - Parent-child product/service add-ons with proportional quantity scaling and boundary clamping (`minValue`, `maxValue`, and inventory levels).
   - Dynamic cart total calculations excluding unavailable items (`OutOfStock`, `SoldOut`, or draft/deleted status).

3. **Backend & Infrastructure Services**
   - **`AppsScriptService`**: Google Apps Script web app communication bridge for order creation and place suggestions.
   - **`PaymentService`**: Google Pay, Apple Pay, UPI (`manishsharma3994@okhdfcbank`, MCC `5251`), and card payment processing with UPI deep-link generation.
   - **`AuthService`**: Firebase Auth session state management, Google Sign-In simulation, phone linking state, and device session sync (`SYNC_DEVICE` / `LOGOUT_DEVICE`).
   - **`GeoVerificationService`**: Indian PIN code validation (6 digits), address form verification, and Schema.org delivery metadata generation (`ParcelDelivery`, `PostalAddress`, `GeoCoordinates`).
   - **`PhoneVerificationService`**: International phone number validation across country codes (`+91`, `+1`, `+44`,and many more) and OTP verification workflow.
   - **`PaginationManager`**: Feed pagination state management (`startIndex`, `maxResults`, `hasMore`, `isLoading`).

## Verification & Testing
- **Unit Tests**: 56 comprehensive unit tests covering schema override, extractors, Blogger service, cart models, payment, auth, geo verification, phone verification, and pagination.
- **Test Status**: All 56 tests passed successfully (`0 errors`).
