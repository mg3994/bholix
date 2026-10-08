import 'dart:convert';
import 'dart:ui' show Locale;

/// Static helpers to extract well-known Schema.org fields from a JSON-LD map.
class SchemaExtractor {
  /// The current UI locale; set this before calling localized extractors.
  static Locale? currentLocale;

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Returns a localized string from a multilingual value node.
  ///
  /// - [String] → returned as-is.
  /// - [List]   → find entry whose '@language' matches [locale.languageCode] or [defaultLanguage],
  ///              falling back to the first plain string or @value in the list.
  /// - [Map]    → return matching `@value` for [locale] or [defaultLanguage] if specified, or `@value`.
  static String? getLocalizedValue(dynamic val, Locale? locale, [String? defaultLanguage]) {
    if (val == null) return null;
    if (val is String) return val;

    final targetLang = locale?.languageCode.toLowerCase() ?? defaultLanguage?.toLowerCase();

    if (val is List) {
      // 1. Try matching preferred language or default language.
      if (targetLang != null) {
        for (final item in val) {
          if (item is Map &&
              item['@language'] != null &&
              item['@language'].toString().toLowerCase() == targetLang &&
              item['@value'] != null) {
            return item['@value']?.toString();
          }
        }
      }
      // 2. Fallback: first plain string or first @value in list.
      for (final item in val) {
        if (item is String) return item;
        if (item is Map && item['@value'] != null) {
          return item['@value']?.toString();
        }
      }
      return null;
    }

    if (val is Map) {
      if (val.containsKey('@value')) {
        if (targetLang != null && val.containsKey('@language')) {
          final lang = val['@language']?.toString().toLowerCase();
          if (lang != null && lang != targetLang) {
            // Still fallback to @value if only one is present
            return val['@value']?.toString();
          }
        }
        return val['@value']?.toString();
      }
      if (val.containsKey('name')) {
        return getLocalizedValue(val['name'], locale, defaultLanguage);
      }
    }

    return null;
  }

  /// Returns the first element of a list, or the value itself if not a list.
  static dynamic getFirst(dynamic val) {
    if (val is List) return val.isEmpty ? null : val.first;
    return val;
  }

  /// Returns val as a List if it is already a List, else [val] or [] if null.
  static List<dynamic> getArray(dynamic val) {
    if (val == null) return [];
    if (val is List) return val;
    return [val];
  }

  /// Normalises a string: trimmed and lowercased.
  static String normalizeName(String name) => name.trim().toLowerCase();

  /// Extracts JSON-LD map from an HTML string containing a `<script type="application/ld+json">` tag.
  static Map<String, dynamic>? extractJsonLd(String html) {
    try {
      final scriptRegex = RegExp(
        r'<script[^>]+type=["' "'" r']application/ld\+json["' "'" r'][^>]*>([\s\S]*?)</script>',
        caseSensitive: false,
      );
      final match = scriptRegex.firstMatch(html);
      String raw = match != null ? match.group(1)! : html;
      raw = raw
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .trim();
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Finds the highest-scoring matching variant given selected attribute maps.
  static Map<String, dynamic>? findMatchingVariant(
    Map<dynamic, dynamic> parent,
    Map<String, String> selectedAttrs, [
    String? lastClickedAttr,
  ]) {
    final variants = getArray(parent['hasVariant']);
    if (variants.isEmpty) return null;

    Map<String, dynamic>? bestMatch;
    int highestScore = -1;

    for (final v in variants) {
      if (v is! Map) continue;
      final variantMap = v.cast<String, dynamic>();
      final props = getArray(variantMap['additionalProperty']);
      int score = 0;

      for (final p in props) {
        if (p is! Map) continue;
        final name = (p['name'] as String?)?.trim();
        final value = (p['value'] as String?)?.trim();
        if (name != null && value != null && selectedAttrs[name] == value) {
          score += (lastClickedAttr != null && name == lastClickedAttr) ? 2 : 1;
        }
      }

      if (score > highestScore) {
        highestScore = score;
        bestMatch = variantMap;
      }
    }

    return bestMatch;
  }

  /// Extracts availability string from an offer or map.
  static String extractAvailability(dynamic offer) {
    if (offer is Map) {
      return (offer['availability'] as String?) ?? '';
    }
    return '';
  }

  /// Extracts eligibleQuantity bounds ({'minValue': int, 'maxValue': int}).
  static Map<String, dynamic> extractEligibleQuantity(Map<dynamic, dynamic> data) {
    final eq = data['eligibleQuantity'];
    if (eq is Map) {
      return {
        'minValue': (eq['minValue'] as num?)?.toInt() ?? 1,
        'maxValue': (eq['maxValue'] as num?)?.toInt() ?? 99,
      };
    }
    return {'minValue': 1, 'maxValue': 99};
  }

  /// Extracts inventoryLevel value.
  static int? extractInventoryLevel(Map<dynamic, dynamic> data) {
    final il = data['inventoryLevel'];
    if (il is Map) {
      final val = il['value'];
      if (val is num) return val.toInt();
    }
    return null;
  }

  /// Recursively walks an object and collects all maps whose @type contains 'Service'.
  static List<Map<String, dynamic>> findAllServices(dynamic obj) {
    final results = <Map<String, dynamic>>[];

    void walk(dynamic current) {
      if (current is List) {
        for (final item in current) {
          walk(item);
        }
      } else if (current is Map) {
        final currentMap = current.cast<String, dynamic>();
        final type = currentMap['@type'];
        if (type != null && type.toString().contains('Service')) {
          results.add(currentMap);
        }
        if (currentMap.containsKey('hasOfferCatalog')) {
          walk(currentMap['hasOfferCatalog']);
        }
        if (currentMap.containsKey('addOn')) {
          walk(currentMap['addOn']);
        }
        if (currentMap.containsKey('itemListElement')) {
          walk(currentMap['itemListElement']);
        }
      }
    }

    walk(obj);
    return results;
  }

  /// Finds a service package in `hasOfferCatalog` matching `packageName`.
  static Map<String, dynamic>? findMatchingServicePackage(
    Map<dynamic, dynamic> parent,
    String packageName,
  ) {
    final normTarget = normalizeName(packageName);
    final catalogs = getArray(parent['hasOfferCatalog']);
    for (final cat in catalogs) {
      if (cat is! Map) continue;
      final elements = getArray(cat['itemListElement']);
      for (final el in elements) {
        if (el is! Map) continue;
        final name = el['name'] as String?;
        if (name != null && normalizeName(name) == normTarget) {
          return el.cast<String, dynamic>();
        }
      }
      final catName = cat['name'] as String?;
      if (catName != null && normalizeName(catName) == normTarget) {
        return cat.cast<String, dynamic>();
      }
    }
    return null;
  }

  // ── Field extractors ────────────────────────────────────────────────────────

  /// Extracts the `name` field (localized).
  static String? extractName(Map<String, dynamic> schema) {
    return getLocalizedValue(schema['name'], currentLocale);
  }

  /// Extracts the `description` field (localized).
  static String? extractDescription(Map<String, dynamic> schema) {
    return getLocalizedValue(schema['description'], currentLocale);
  }

  /// Extracts a single image URL from `image` (first ImageObject url or plain string).
  static String? extractImage(Map<String, dynamic> schema) {
    final raw = getFirst(schema['image']);
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) {
      final url = raw['url'] ?? raw['contentUrl'];
      if (url is String) return url;
    }
    return null;
  }

  /// Extracts all image URLs from `image`.
  static List<String> extractImages(Map<String, dynamic> schema) {
    final raw = schema['image'];
    if (raw == null) return [];

    final items = raw is List ? raw : [raw];
    final result = <String>[];

    for (final item in items) {
      if (item is String) {
        result.add(item);
      } else if (item is Map) {
        final url = item['url'] ?? item['contentUrl'];
        if (url is String) result.add(url);
      }
    }
    return result;
  }

  /// Extracts the price from `offers.price`, `itemOffered.offers.price`,
  /// `priceSpecification`, or top-level `price`.
  static String? extractPrice(Map<String, dynamic> schema) {
    final directPrice = schema['price'];
    if (directPrice != null) return directPrice.toString();

    final offers = getFirst(schema['offers']);
    if (offers is Map) {
      final price = offers['price'];
      if (price != null) return price.toString();

      final priceSpec = getFirst(offers['priceSpecification']);
      if (priceSpec is Map && priceSpec['price'] != null) {
        return priceSpec['price'].toString();
      }
    }

    final itemOffered = getFirst(schema['itemOffered']);
    if (itemOffered is Map) {
      final itemOffers = getFirst(itemOffered['offers']);
      if (itemOffers is Map && itemOffers['price'] != null) {
        return itemOffers['price'].toString();
      }
    }

    final priceSpec = getFirst(schema['priceSpecification']);
    if (priceSpec is Map && priceSpec['price'] != null) {
      return priceSpec['price'].toString();
    }

    return null;
  }

  /// Extracts the price currency from `offers.priceCurrency`, `itemOffered.offers`,
  /// `priceSpecification`, or top-level.
  static String? extractPriceCurrency(Map<String, dynamic> schema) {
    final direct = schema['priceCurrency'];
    if (direct is String) return direct;

    final offers = getFirst(schema['offers']);
    if (offers is Map) {
      final currency = offers['priceCurrency'];
      if (currency is String) return currency;

      final priceSpec = getFirst(offers['priceSpecification']);
      if (priceSpec is Map && priceSpec['priceCurrency'] is String) {
        return priceSpec['priceCurrency'] as String;
      }
    }

    final itemOffered = getFirst(schema['itemOffered']);
    if (itemOffered is Map) {
      final itemOffers = getFirst(itemOffered['offers']);
      if (itemOffers is Map && itemOffers['priceCurrency'] is String) {
        return itemOffers['priceCurrency'] as String;
      }
    }

    return null;
  }

  /// Extracts the SKU.
  static String? extractSku(Map<String, dynamic> schema) {
    final sku = schema['sku'];
    if (sku is String) return sku;
    return null;
  }

  /// Extracts the brand name from `brand.name`.
  static String? extractBrand(Map<String, dynamic> schema) {
    final brand = schema['brand'];
    if (brand is Map) {
      return getLocalizedValue(brand['name'], currentLocale);
    }
    if (brand is String) return brand;
    return null;
  }

  /// Extracts `hasVariant` as a list of maps.
  static List<Map<String, dynamic>> extractVariants(
    Map<String, dynamic> schema,
  ) {
    final raw = schema['hasVariant'];
    if (raw == null) return [];
    final items = raw is List ? raw : [raw];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  /// Extracts `addOn` as a list of maps.
  static List<Map<String, dynamic>> extractAddons(Map<String, dynamic> schema) {
    final raw = schema['addOn'];
    if (raw == null) return [];
    final items = raw is List ? raw : [raw];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  /// Extracts service packages from `hasOfferCatalog[].itemListElement[]`.
  /// Returns a flat list of offer maps, each with at minimum `name` and `price`.
  static List<Map<String, dynamic>> extractPackages(
    Map<String, dynamic> schema,
  ) {
    final raw = schema['hasOfferCatalog'];
    if (raw == null) return [];
    final catalogs = raw is List ? raw : [raw];
    final result = <Map<String, dynamic>>[];
    for (final catalog in catalogs) {
      if (catalog is! Map<String, dynamic>) continue;
      final elements = catalog['itemListElement'];
      if (elements == null) continue;
      final items = elements is List ? elements : [elements];
      for (final item in items) {
        if (item is Map<String, dynamic>) result.add(item);
      }
    }
    return result;
  }

  /// Extracts `areaServed` normalised to a list of maps.
  /// Strings are wrapped as `{'@type': 'PostalCode', 'postalCode': value}`.
  static List<Map<String, dynamic>> extractAreaServed(
    Map<String, dynamic> schema,
  ) {
    final raw = schema['areaServed'];
    if (raw == null) return [];

    final items = raw is List ? raw : [raw];
    final result = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item is Map<String, dynamic>) {
        result.add(item);
      } else if (item is String) {
        result.add({'@type': 'PostalCode', 'postalCode': item});
      }
    }
    return result;
  }

  /// Extracts the `seller` map.
  static Map<String, dynamic>? extractSeller(Map<String, dynamic> schema) {
    final seller = schema['seller'];
    if (seller is Map<String, dynamic>) return seller;
    return null;
  }

  /// Extracts `additionalProperty` as a list of maps.
  static List<Map<String, dynamic>> extractAdditionalProperties(
    Map<String, dynamic> schema,
  ) {
    final raw = schema['additionalProperty'];
    if (raw == null) return [];
    final items = raw is List ? raw : [raw];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  /// Extracts the `availability` string (from `offers.availability` or top-level).
  static String? extractStockLevel(Map<String, dynamic> schema) {
    final offers = getFirst(schema['offers']);
    if (offers is Map) {
      final avail = offers['availability'];
      if (avail is String) return avail;
    }
    final avail = schema['availability'];
    if (avail is String) return avail;
    return null;
  }

  /// Extracts advance booking requirement (e.g. "24 Hours" or "2 Days").
  static String? extractAdvanceBookingRequirement(dynamic offer) {
    final off = getFirst(offer);
    if (off is! Map) return null;

    final abr = getFirst(off['advanceBookingRequirement']);
    if (abr == null) return null;
    if (abr is String) return abr;

    if (abr is Map) {
      final val = getFirst(abr['value']);
      final unit = getFirst(abr['unitCode']) ?? getFirst(abr['unitText']) ?? '';
      if (val == null) return null;

      var unitLabel = unit.toString();
      if (unit == 'HUR') {
        unitLabel = 'Hours';
      } else if (unit == 'DAY') {
        unitLabel = 'Days';
      }

      return '$val $unitLabel'.trim();
    }
    return null;
  }
}
