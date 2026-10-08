---
name: jsonld-schema-engine
version: 1
description: Spec and guide for the JSON-LD Schema.org micro-data parsing engine in bholix, including @base resolution, @id deep graph node merging, @language multilingual extraction, and HTML script tag extraction.
---

# JSON-LD Schema Engine Skill

Use this skill whenever working with, modifying, or porting the core Schema.org JSON-LD micro-data parsing and extraction engine.

## Core Files
- `lib/core/schema/schema_override.dart`: ID path resolution, `@base` context extraction, and deep map node merging.
- `lib/core/schema/schema_extractor.dart`: Multilingual value resolution, HTML script parsing, variant matching, offer catalog extraction, and service/add-on traversal.
- `lib/core/schema/geo_filter.dart`: Location-based deliverability validation against `areaServed`.

## Fundamental Rules
1. **URI Resolution (`SchemaOverride.resolveId`)**:
   - Handle absolute HTTP/HTTPS URLs.
   - Handle `"blogId/postId"` formatted path strings.
   - Handle relative paths against parent base contexts or relative URIs against base domain URLs.
2. **Deep Merging (`SchemaOverride.deepMerge`)**:
   - When merging graph nodes sharing the same `@id`, non-null nested maps are merged recursively. Primitives and lists in source overwrite target.
3. **Multilingual Fallbacks (`SchemaExtractor.getLocalizedValue`)**:
   - Strictly follow the lookup order: `Requested UI Locale -> Default Language Tag -> First String/Value in Array`.
4. **HTML Entity Unescaping (`SchemaExtractor.extractJsonLd`)**:
   - Always unescape `&quot;`, `&amp;`, `&#39;`, `&apos;`, `&lt;`, `&gt;` prior to JSON parsing.

## Documentation References
- Detailed Specification: `docs/01_schema_engine_spec.md`
- System Architecture: `arch/01_system_architecture.md`
- Porting Prompts: `prompts/01_schema_engine_porting_prompts.md`
