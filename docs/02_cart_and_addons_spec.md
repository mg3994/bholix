# Cart & Add-ons Specification

## Overview
This document specifies the exact domain models, state transitions, boundary math, dynamic scaling rules, and price calculation logic for the Cart & Add-ons subsystem.

---

## 1. Domain Data Models

### `CartItem`
```types
CartItem {
  item: Map<String, Any>             // Schema.org JSON-LD Product or Service
  quantity: Int                       // Parent item quantity
  selectedPackageName: String?        // Optional service package selection
  addOns: List<CartAddOn>            // Child add-ons attached to this parent
}
```

### `CartAddOn`
```types
CartAddOn {
  rawAddOn: Map<String, Any>         // Schema.org JSON-LD Add-on Service or Product
  quantity: Int                      // Add-on quantity
}
```

---

## 2. Quantity Clamping & Boundary Math

Each item or add-on schema contains boundary rules derived from `eligibleQuantity` and `inventoryLevel`:

```json
{
  "eligibleQuantity": {
    "minValue": 1,
    "maxValue": 10
  },
  "inventoryLevel": {
    "value": 5
  }
}
```

### Effective Bounds Formula:
* $\text{minValue} = \text{schema.eligibleQuantity.minValue} \text{ (default 1)}$
* $\text{maxValue} = \text{schema.eligibleQuantity.maxValue} \text{ (default 99)}$
* $\text{inventoryLevel} = \text{schema.inventoryLevel.value} \text{ (if present)}$

$$\text{effectiveMax} = \begin{cases} \min(\text{maxValue}, \text{inventoryLevel}), & \text{if inventoryLevel present} \\ \text{maxValue}, & \text{otherwise} \end{cases}$$

### Clamped Quantity Formula:
$$\text{clampedQuantity}(Q_{\text{desired}}) = \max\left(\text{minValue}, \min\left(Q_{\text{desired}}, \text{effectiveMax}\right)\right)$$

---

## 3. Proportional Add-on Quantity Scaling

When parent item quantity updates from $Q_{\text{parent\_old}}$ to $Q_{\text{parent\_new}}$:

1. **Scaling Ratio**:
   $$R = \frac{Q_{\text{parent\_new}}}{Q_{\text{parent\_old}}}$$

2. **Add-on Scaling Calculation**:
   For each `addon` in `addOns`:
   $$Q_{\text{addon\_prelim}} = \left\lfloor Q_{\text{addon\_old}} \times R \right\rfloor$$
   $$Q_{\text{addon\_new}} = \text{addon.clampedQuantity}(Q_{\text{addon\_prelim}})$$

---

## 4. Price Calculation Engine

### Unit Price Extraction:
1. If `selectedPackageName` is present:
   Find package in `item.hasOfferCatalog` matching `selectedPackageName` and extract `price`.
2. Otherwise:
   Extract price from `item.offers.price`, `item.priceSpecification.price`, or top-level `item.price`.
3. Parse string to numeric float/double value. Return `0.0` if parsing fails or item is `OutOfStock`/`SoldOut`.

### Item Total Price Formula:
$$\text{ItemTotal} = \left(\text{UnitPrice}_{\text{parent}} \times Q_{\text{parent}}\right) + \sum_{a \in \text{addOns}} \left(\text{UnitPrice}_{a} \times Q_{a}\right)$$

### Cart Subtotal Price Formula:
$$\text{CartSubtotal} = \sum_{i \in \text{validCartItems}} \text{ItemTotal}_{i}$$
where $\text{validCartItems}$ excludes items marked `OutOfStock`, `SoldOut`, or draft/deleted state.
