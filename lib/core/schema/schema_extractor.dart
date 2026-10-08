import 'dart:ui' show Locale;

/// Static helpers to extract well-known Schema.org fields from a JSON-LD map.
class SchemaExtractor {
  /// The current UI locale; set this before calling localized extractors.
  static Locale? currentLocale;

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Returns a localized string from a multilingual value node.
  ///
  /// - [String] → returned as-is.
  /// - [List]   → find entry whose '@language' matches [locale.languageCode],
  ///              falling back to the first plain string in the list.
  /// - [Map]    → return `val['@value']` as String.
  static String? getLocalizedValue(dynamic val, Locale? locale) {
    if (val == null) return null;
    if (val is String) return val;

    if (val is List) {
      // Try locale match first.
      if (locale != null) {
        for (final item in val) {
          if (item is Map &&
              item['@language'] == locale.languageCode &&
              item['@value'] != null) {
            return item['@value'] as String?;
          }
        }
      }
      // Fallback: first plain string or first @value in list.
      for (final item in val) {
        if (item is String) return item;
        if (item is Map && item['@value'] != null) {
          return item['@value'] as String?;
        }
      }
      return null;
    }

    if (val is Map) return val['@value'] as String?;

    return null;
  }

  /// Returns the first element of a list, or the value itself if not a list.
  static dynamic getFirst(dynamic val) {
    if (val is List) return val.isEmpty ? null : val.first;
    return val;
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

  /// Extracts the price from `offers.price` or top-level `price`.
  static String? extractPrice(Map<String, dynamic> schema) {
    final offers = getFirst(schema['offers']);
    if (offers is Map) {
      final price = offers['price'];
      if (price != null) return price.toString();
    }
    final price = schema['price'];
    if (price != null) return price.toString();
    return null;
  }

  /// Extracts the price currency from `offers.priceCurrency` or top-level.
  static String? extractPriceCurrency(Map<String, dynamic> schema) {
    final offers = getFirst(schema['offers']);
    if (offers is Map) {
      final currency = offers['priceCurrency'];
      if (currency is String) return currency;
    }
    final currency = schema['priceCurrency'];
    if (currency is String) return currency;
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
}
