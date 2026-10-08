# 02 Data & Domain Architecture

## Overview
This document specifies the core domain entities, data models, Blogger CMS integration, and cart pricing engine within `bholix`.

---

## 1. Cart Model Hierarchy & Engine (`lib/core/cart/`)

### Cart Models (`lib/core/cart/cart_models.dart`)

The cart system models hierarchical e-commerce purchases consisting of main items (Products or Services) and nested add-ons.

```
┌────────────────────────────────────────────────────────────┐
│                          CartItem                          │
│  - item: Map<String, dynamic> (Schema.org JSON-LD Map)     │
│  - quantity: int                                           │
│  - selectedPackageName: String?                            │
│  - addOns: List<CartAddOn>                                 │
└─────────────────────────────┬──────────────────────────────┘
                              │ 1:N
                              ▼
┌────────────────────────────────────────────────────────────┐
│                         CartAddOn                          │
│  - rawAddOn: Map<String, dynamic> (Schema.org JSON-LD Map) │
│  - quantity: int                                           │
└────────────────────────────────────────────────────────────┘
```

#### Key Domain Rules & Invariants:
1. **Quantity Boundaries**:
   `CartItem.clampedQuantity(int newQty)` and `CartAddOn.clampedQuantity(int newQty)` clamp desired quantity using bounds derived from `eligibleQuantity`:
   $$\text{clampedQty} = \min(\max(\text{newQty}, \text{minValue}), \text{effectiveMax})$$
   where $\text{effectiveMax} = \min(\text{maxValue}, \text{inventoryLevel} \text{ if present})$.
2. **Proportional Add-on Scaling**:
   When parent `CartItem` quantity changes from $Q_{old}$ to $Q_{new}$, each child `CartAddOn` quantity scales proportionally:
   $$Q_{addon\_new} = \left\lfloor Q_{addon\_old} \times \frac{Q_{new}}{Q_{old}} \right\rfloor$$
   and is then clamped against the add-on's own boundary constraints.
3. **Availability Filtering**:
   Items or add-ons marked as `OutOfStock`, `SoldOut`, or missing price are excluded from dynamic total price calculations.

---

## 2. Blogger Data Integration (`lib/core/services/blogger_service.dart`)

The application integrates with Blogger API v3 (`BloggerService`) as a headless content store.

### Key Data Transformations:
* **HTML Feed Parsing**:
  Blogger post contents contain embedded Schema.org JSON-LD inside HTML `<script type="application/ld+json">` tags.
* **Graph Document Normalization (`toGraphDocument`)**:
  Multiple post feeds are combined into a top-level `@graph` document:
  ```json
  {
    "@context": { "@base": "https://example.blogger.com/" },
    "@graph": [
      { "@id": "post-1", "@type": "Product", ... },
      { "@id": "post-2", "@type": "Service", ... }
    ]
  }
  ```
  Nodes sharing the same `@id` are automatically deep-merged using `SchemaOverride.deepMerge`.

---

## 3. Storage & Local Persistence (`lib/core/wishlist/`)

* **Wishlist Repository (`WishlistRepository`)**:
  Manages local persistence for favorited schema items.
* **Storage Abstraction**:
  Backed by Drift ORM (SQLite database) or web local storage, storing serialized schema `@id` and full JSON-LD string representations.

---

## Language Porting Checklist
* [ ] Implement immutable `CartItem` and `CartAddOn` data structures with copy/clone helpers.
* [ ] Port `clampedQuantity` mathematical formulas and boundary checks.
* [ ] Implement proportional add-on scaling upon parent quantity updates.
* [ ] Port Blogger Feed JSON-LD parser and unescaping logic.
