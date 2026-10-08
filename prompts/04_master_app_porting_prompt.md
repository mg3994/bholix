# Master Application Porting Prompt

Use this master prompt when instructing an AI assistant or human developer to port the entire `bholix` application stack end-to-end to a new platform or tech stack.

---

```text
System Role: You are an expert principal mobile/web engineer tasked with re-architecting and porting the bholix e-commerce application (Antinna Engine) to [TARGET_TECH_STACK, e.g., Swift/SwiftUI, Kotlin/Jetpack Compose, React Native/TypeScript, Flutter].

Context & Repository Structure:
The bholix repository uses Schema.org JSON-LD micro-data as its primary data model. All architectural specs, data specs, service specs, and algorithms are documented in the repo:
- System Architecture: arch/01_system_architecture.md
- Data & Domain: arch/02_data_and_domain.md
- State & Routing: arch/03_state_and_routing.md
- Backend Integrations: arch/04_backend_and_integrations.md
- Detailed Specs: docs/01_schema_engine_spec.md, docs/02_cart_and_addons_spec.md, docs/03_services_and_api_spec.md
- Porting Guide: docs/04_cross_language_porting_guide.md

Execution Strategy:

Step 1: Core Schema Engine
- Implement dynamic JSON map parsing.
- Implement SchemaOverride (relative @id resolution, @base extraction, deep graph node merging).
- Implement SchemaExtractor (multilingual @language value resolution, HTML <script> extraction, property scoring for variant matching, service & add-on tree walking).

Step 2: Cart Domain & Boundary Math
- Implement CartItem and CartAddOn models.
- Implement quantity boundary clamping: min(maxValue, inventoryLevel ?? maxValue).
- Implement proportional add-on quantity scaling on parent quantity changes.
- Implement dynamic cart subtotal calculation excluding OutOfStock/SoldOut items.

Step 3: Services & Integrations
- Implement AppsScriptService (order creation POST, place suggestions GET).
- Implement PaymentService (upi://pay URI deep link generation with VPA manishsharma3994@okhdfcbank, MCC 5251).
- Implement GeoVerificationService (Indian PIN code regex ^[1-9][0-9]{5}$, Schema.org ParcelDelivery generator).
- Implement PhoneVerificationService (E.164 phone formatting and OTP workflow state machine).

Step 4: State Management & Navigation UI
- Connect reactive state management (signals/observables) to Cart, Grid, Location, and Product screens.
- Implement type-safe sealed class / discriminated union routing.
- Construct UI screens: Product details page with image carousel, variant selector, service package cards, add-on section; Cart sheet/page; Location picker sheet; Grid feed.

Verification & Quality Control:
- Port and execute all 56 unit tests from test/unit/ across schema override, schema extractor, blogger service, cart models, payment, auth, geo verification, phone verification, and pagination. Ensure 100% test pass rate.
```
