# JSON-LD Schema Engine Specification

## Overview
This document serves as the complete technical reference for the JSON-LD parsing and extraction engine. Any implementation in another language (Java, Kotlin, Swift, TypeScript, Rust, Go) must follow the logic defined below to maintain behavior compatibility.

---

## 1. Schema Base & Path Resolution (`SchemaOverride`)

### Algorithm: `resolveId(base: String, idValue: String) -> ResolvedId`

1. If `idValue` is empty $\rightarrow$ return `ResolvedId()` (all fields null).
2. If `idValue` starts with `"http://"` or `"https://"` $\rightarrow$ return `ResolvedId(url: idValue)`.
3. Split `idValue` by `'/'`. If `parts.length == 2` AND `parts[0]` is not empty AND `parts[1]` is not empty:
   $\rightarrow$ return `ResolvedId(blogId: parts[0], postId: parts[1])`.
4. If `base` contains `'/'` AND does NOT start with `"http://"` or `"https://"`:
   $\rightarrow$ split `base` by `'/'`. If `baseParts[0]` is not empty:
   $\rightarrow$ return `ResolvedId(blogId: baseParts[0], postId: idValue)`.
5. If `base` starts with `"http://"` or `"https://"`:
   $\rightarrow$ resolve relative URL using standard URL resolution logic (`base` as base URI, `idValue` as target).
   $\rightarrow$ return `ResolvedId(url: resolvedUrl)`.
6. Fallback $\rightarrow$ return `ResolvedId(url: idValue)`.

### Algorithm: `deepMerge(target: Map, source: Map) -> Map`

Creates a new dictionary starting with a shallow copy of `target`.
For each key `k` and value `v_source` in `source`:
- If `v_source` is a Map AND `target[k]` is also a Map:
  $\rightarrow$ `output[k] = deepMerge(target[k], v_source)`
- Else:
  $\rightarrow$ `output[k] = v_source`

Return `output`.

---

## 2. Multilingual Localization (`SchemaExtractor.getLocalizedValue`)

### Function: `getLocalizedValue(val: Any?, locale: Locale?, defaultLanguage: String?) -> String?`

1. If `val == null` $\rightarrow$ return `null`.
2. If `val` is `String` $\rightarrow$ return `val`.
3. Determine `targetLang` = `locale?.languageCode?.toLowerCase()` ?? `defaultLanguage?.toLowerCase()`.
4. If `val` is `List`:
   a. If `targetLang` is not null:
      - Iterate through list. If item is `Map` AND `item['@language']?.toLowerCase() == targetLang` AND `item['@value'] != null`:
        $\rightarrow$ return `item['@value'].toString()`.
   b. Fallback loop through list:
      - If item is `String` $\rightarrow$ return item.
      - If item is `Map` AND `item['@value'] != null` $\rightarrow$ return `item['@value'].toString()`.
   c. Return `null`.
5. If `val` is `Map`:
   a. If `val` contains `@value`:
      - If `targetLang` != null AND `val` contains `@language`:
        - If `val['@language']?.toLowerCase() != targetLang`, still return `@value` if no other alternative exists.
      - Return `val['@value'].toString()`.
   b. If `val` contains `name`:
      - Return `getLocalizedValue(val['name'], locale, defaultLanguage)`.
6. Return `null`.

---

## 3. HTML Embedded JSON-LD Extraction (`SchemaExtractor.extractJsonLd`)

### Function: `extractJsonLd(html: String) -> Map<String, Any>?`

1. Regex pattern: `<script[^>]+type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>` (case-insensitive).
2. Match against `html`. Extract captured group 1 if matched; otherwise use raw `html`.
3. Replace HTML entities in string:
   - `&quot;` $\rightarrow$ `"`
   - `&amp;` $\rightarrow$ `&`
   - `&#39;` $\rightarrow$ `'`
   - `&apos;` $\rightarrow$ `'`
   - `&lt;` $\rightarrow$ `<`
   - `&gt;` $\rightarrow$ `>`
4. Parse clean string as JSON map. Return null on error.

---

## 4. Variant Attributes Matching (`SchemaExtractor.findMatchingVariant`)

### Function: `findMatchingVariant(parent: Map, selectedAttrs: Map<String, String>, lastClickedAttr: String?) -> Map?`

1. Extract variants list `hasVariant` from `parent`.
2. Iterate each variant `v` in variants:
   - Extract `additionalProperty` list from `v`.
   - Calculate match score:
     For each property `p` in `additionalProperty`:
       - If `p.name` and `p.value` match `selectedAttrs[p.name]`:
         - Score increases by 2 if `p.name == lastClickedAttr`, otherwise 1.
3. Return variant map with highest score (or null if no variants exist).
