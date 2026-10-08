# bholix (Antinna Engine)

`bholix` is an e-commerce platform built on **Schema.org JSON-LD micro-data**, driven by reactive signals (`bloc_signals`), sealed-class routing (`kaisel`), dynamic parent-child product/service add-on nesting, and Google Apps Script serverless integrations.

---

## Technical Guides & Documentation Map

For full details on architecture, system specs, cross-language porting blueprints, AI prompts, and agent skills, explore the following dedicated directories:

### 1. System Architecture (`arch/`)
- [01 System Architecture](arch/01_system_architecture.md): High-level system design, JSON-LD schema parsing engine, URI resolution, and deep graph node merging.
- [02 Data & Domain Architecture](arch/02_data_and_domain.md): Domain data models, Blogger API integration, cart pricing engine, and storage.
- [03 State & Routing Architecture](arch/03_state_and_routing.md): Reactive state management (`bloc_signals`), type-safe sealed class routing (`kaisel`), and compile-time configuration.
- [04 Backend & Integrations Architecture](arch/04_backend_and_integrations.md): Google Apps Script bridge, Payment processing (UPI deep links, Google Pay), address geo-verification, and phone parsing.

### 2. Technical Specifications & Porting (`docs/`)
- [01 JSON-LD Schema Engine Spec](docs/01_schema_engine_spec.md): Exact algorithms for `@base` resolution, `@id` deep merge, `@language` fallbacks, HTML script extraction, and variant attribute scoring.
- [02 Cart & Add-ons Spec](docs/02_cart_and_addons_spec.md): Domain models, boundary clamping formulas, proportional add-on scaling, and subtotal calculations.
- [03 Services & API Spec](docs/03_services_and_api_spec.md): Endpoint specifications, UPI URI format (`manishsharma3994@okhdfcbank`), PIN code regex, and E.164 phone parsing.
- [04 Cross-Language Porting Guide](docs/04_cross_language_porting_guide.md): Step-by-step blueprint for re-implementing `bholix` in Swift/SwiftUI, Kotlin/Android, TypeScript/React Native, Rust, or Go.

### 3. AI Prompts for Porting (`prompts/`)
- [01 Schema Engine Prompts](prompts/01_schema_engine_porting_prompts.md): Prompts to generate or port the JSON-LD engine to any target language.
- [02 Cart & Add-ons Prompts](prompts/02_cart_addons_porting_prompts.md): Prompts to port parent-child add-on scaling and clamping logic.
- [03 Services Prompts](prompts/03_services_porting_prompts.md): Prompts to port AppsScript bridge, UPI URI generators, and geo/phone verification.
- [04 Master Porting Prompt](prompts/04_master_app_porting_prompt.md): End-to-end master prompt to port the entire app stack.

### 4. Agent Skills (`.agents/skills/`)
- [JSON-LD Schema Engine Skill](.agents/skills/jsonld-schema-engine/SKILL.md)
- [Cart & Add-ons Nesting Skill](.agents/skills/cart-addons-nesting/SKILL.md)
- [Backend Integrations Skill](.agents/skills/backend-integrations/SKILL.md)
- [Architecture & Porting Skill](.agents/skills/architecture-porting/SKILL.md)
- [App Core Config Skill](.agents/skills/app-core-config/SKILL.md)

---

## Core Features
- **Dynamic Schema Processing**: Parses Schema.org `Product`, `Service`, `Offer`, `PostalAddress`, `ParcelDelivery`, and `GeoCoordinates` directly from JSON-LD or embedded HTML `<script>` tags.
- **Hierarchical Add-ons**: Supports nested parent-child service/product add-ons with automatic proportional quantity scaling and boundary clamping (`minValue`, `maxValue`, `inventoryLevel`).
- **Unified Payment Engine**: Supports UPI deep-linking (`manishsharma3994@okhdfcbank`), Google Pay, Apple Pay, and Card checkout.
- **Geo & Phone Verification**: Indian PIN code validation, international E.164 phone number formatting, and OTP verification workflows.
