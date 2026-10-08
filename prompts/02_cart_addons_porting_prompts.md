# Cart & Add-ons Porting Prompts

Use these exact prompt templates when instructing an AI assistant to port the `bholix` Cart & Add-ons domain models, boundary math, and pricing logic to another programming language or tech stack.

---

## Prompt: Porting Cart Models, Boundary Math, & Price Calculations

```text
Task: Port the Cart & Add-ons nesting engine from Dart to [TARGET_LANGUAGE].

Requirements:
1. Define Data Models:
   - CartAddOn: contains rawAddOn (Map/JSON) and quantity (Int).
   - CartItem: contains item (Map/JSON), quantity (Int), selectedPackageName (String?), and addOns (List<CartAddOn>).
2. Boundary Clamping Math:
   - Extract minValue (default 1) and maxValue (default 99) from schema["eligibleQuantity"].
   - Extract inventoryLevel from schema["inventoryLevel"]["value"].
   - Calculate effectiveMax = inventoryLevel != null ? min(maxValue, inventoryLevel) : maxValue.
   - Implement clampedQuantity(desiredQty): max(minValue, min(desiredQty, effectiveMax)).
3. Proportional Add-on Scaling:
   - When parent item quantity changes from oldQty to newQty, scale each child add-on quantity proportionally:
     newAddOnQty = floor(oldAddOnQty * (newQty / oldQty))
   - Clamp newAddOnQty using the add-on's own boundary bounds.
4. Total Price Calculation:
   - Parent Unit Price: extract from selected package in hasOfferCatalog OR offers.price OR priceSpecification.price OR price.
   - Child Add-on Unit Price: extract price from child rawAddOn map.
   - Total Item Price = (parentUnitPrice * parentQty) + sum(childUnitPrice * childQty).
   - Cart Subtotal = sum of Total Item Price across items, excluding items marked OutOfStock or SoldOut.

Reference Specifications:
- docs/02_cart_and_addons_spec.md
- lib/core/cart/cart_models.dart

Please write clean, idiomatic [TARGET_LANGUAGE] code with unit tests testing quantity clamping, proportional add-on scaling, and out-of-stock item exclusions.
```
