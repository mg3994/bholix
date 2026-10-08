# Schema Engine Porting Prompts

Use these exact prompt templates when instructing an AI assistant to port the `bholix` Schema.org JSON-LD parsing engine to another programming language or tech stack.

---

## Prompt 1: Porting `SchemaOverride` (Base Context & Node Merge)

```text
Task: Port the SchemaOverride utility class from Dart to [TARGET_LANGUAGE].

Requirements:
1. Create a class/module named SchemaOverride with static functions:
   a. resolveId(base: String, idValue: String) -> ResolvedId
      - If idValue is empty -> return empty ResolvedId.
      - If idValue starts with "http://" or "https://" -> ResolvedId(url: idValue).
      - Split idValue by '/'. If exactly 2 non-empty parts -> ResolvedId(blogId: part[0], postId: part[1]).
      - If base contains '/' and is not http(s) -> split base by '/'. If first part non-empty -> ResolvedId(blogId: base[0], postId: idValue).
      - If base is http(s) URL -> resolve relative URI against base URI -> ResolvedId(url: resolvedUrl).
      - Fallback -> ResolvedId(url: idValue).
   b. deepMerge(target: Map, source: Map) -> Map
      - Recursively merge source map into target map.
      - Non-null Maps in source & target should merge recursively; primitives or lists in source overwrite target.
   c. extractBase(schema: Map) -> String?
      - Extract @base from schema root or schema["@context"].
   d. extractDefaultLanguage(schema: Map) -> String?
      - Extract @language from schema root or schema["@context"].

Reference Dart source:
lib/core/schema/schema_override.dart in bholix repo.

Please write clean, idiomatic [TARGET_LANGUAGE] code accompanied by comprehensive unit tests covering all edge cases.
```

---

## Prompt 2: Porting `SchemaExtractor` (Multilingual Extraction & Traversal)

```text
Task: Port the SchemaExtractor helper class from Dart to [TARGET_LANGUAGE].

Requirements:
1. Implement getLocalizedValue(val: Any?, locale: Locale?, defaultLanguage: String?) -> String?:
   - If string -> return as-is.
   - If list -> search for entry with matching '@language' tag (case-insensitive). If none, fallback to first string or map with '@value'.
   - If map -> extract '@value' property if language matches or fallback available.
2. Implement extractJsonLd(html: String) -> Map<String, Any>?:
   - Extract content inside <script type="application/ld+json"> using regex.
   - Unescape HTML entities (&quot;, &amp;, &#39;, &apos;, &lt;, &gt;).
   - Parse clean string as JSON map.
3. Implement findMatchingVariant(parent: Map, selectedAttrs: Map<String, String>, lastClickedAttr: String?) -> Map?:
   - Score variants in parent["hasVariant"] matching selectedAttrs.
   - Give 2 points for matching lastClickedAttr, 1 point for other matching attributes. Return variant map with highest score.
4. Implement extractors: extractName, extractDescription, extractPrice, extractPriceCurrency, extractImages, extractBrand, extractAddons, extractPackages.

Reference Dart source:
lib/core/schema/schema_extractor.dart in bholix repo.

Please write clean, idiomatic [TARGET_LANGUAGE] code accompanied by comprehensive unit tests.
```
