# 01 System Architecture

## Overview
`bholix` (formerly Antinna Engine) is an e-commerce platform built around **Schema.org JSON-LD micro-data**. Rather than relying on rigid, traditional relational API schemas, the core system operates directly on semantically-rich JSON-LD documents parsed from headless CMS feeds (such as Blogger posts/pages) or dedicated API endpoints.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Data Sources / CMS Feeds                        │
│                (Blogger Feed API / Google Apps Script)                 │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ JSON / HTML JSON-LD Script
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          Schema Parsing Engine                         │
│  - @base relative URI resolution      - @id deep graph node merging    │
│  - Multilingual @language extractor   - Custom HTML <script> extraction│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Normalized Dynamic Schema Maps
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Domain & Business Layer                         │
│  - Cart Engine (Parent-Child add-on scaling, quantity boundary clamps) │
│  - Payment Service (UPI Deep Links, Google Pay, Apple Pay)             │
│  - Address & Geo Verification (PIN code validation, ParcelDelivery)    │
│  - Phone Verification (E.164, country code parsing, OTP workflow)      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Reactive Signals & Sealed Routes
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Presentation Layer (UI)                         │
│  - Page/Sheet components driven by bloc_signals & kaisel router        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## JSON-LD Engine Architecture

The schema processing engine is located in `lib/core/schema/` and consists of three foundational components:

### 1. `SchemaOverride` (`lib/core/schema/schema_override.dart`)
Handles URI normalization, graph merging, and root-level context extraction.

* **Base Context Extraction (`extractBase`)**:
  Extracts `@base` from either the root schema map or its `@context` dictionary.
* **Resolved ID Resolution (`resolveId`)**:
  Resolves relative `@id` references into structured `ResolvedId(blogId, postId, url)` according to a five-case fallback algorithm:
  1. **Absolute URL**: Starts with `http://` or `https://` $\rightarrow$ `ResolvedId(url: idValue)`.
  2. **Direct Path**: Formatted as `"blogId/postId"` (two non-empty segments) $\rightarrow$ `ResolvedId(blogId: parts[0], postId: parts[1])`.
  3. **Relative Path with Context**: Base contains `'/'` $\rightarrow$ `ResolvedId(blogId: base.split('/')[0], postId: idValue)`.
  4. **Relative URL with Context**: Base is absolute URL $\rightarrow$ Uses `Uri.resolve()` to derive absolute URL.
  5. **Fallback**: Returns `ResolvedId(url: idValue)`.
* **Deep Merge (`deepMerge`)**:
  Recursively merges two JSON-LD maps. Non-null Map properties are merged recursively; primitives and lists in `source` overwrite those in `target`.

### 2. `SchemaExtractor` (`lib/core/schema/schema_extractor.dart`)
Extracts localized values, variant attributes, price specifications, offer catalogs, and nested services.

* **Multilingual String Resolution (`getLocalizedValue`)**:
  Evaluates localized strings across strings, lists, or maps against target UI `Locale` and fallback default language.
* **HTML Script Tag Parser (`extractJsonLd`)**:
  Regex-based extraction of `<script type="application/ld+json">...</script>` tags inside HTML bodies, unescaping HTML entities (`&quot;`, `&amp;`, `&#39;`, `&apos;`, `&lt;`, `&gt;`).
* **Variant Matching (`findMatchingVariant`)**:
  Scores variants by matching `additionalProperty` key-value pairs against user selections, boosting scores for the `lastClickedAttr`.
* **Service & Add-On Traversal (`findAllServices`)**:
  Recursively walks schema trees collecting nodes whose `@type` contains `'Service'`, inspecting `hasOfferCatalog`, `addOn`, and `itemListElement`.

### 3. `GeoFilter` (`lib/core/schema/geo_filter.dart`)
Validates whether a product or service is deliverable or available in a user's location based on `areaServed` declarations.
* Evaluates `PostalCode` matches, city/region matches, and nation-wide availability fallbacks.

---

## Portability Requirements
When porting this architecture to another tech stack (e.g., TypeScript/Node, Kotlin/Android, Swift/iOS, Go, Rust):
1. **Schema Mapping**: Treat raw data as flexible `Map<String, Any>` or JSON AST rather than rigid, static DTOs until dynamic attributes are resolved.
2. **Deterministic Deep Merge**: Ensure graph node merging preserves nested properties when `@id` collision occurs.
3. **Multilingual Fallback Chain**: Strictly honor the language lookup order: `Requested Locale -> Default Context Language -> First String/Value in Array`.
