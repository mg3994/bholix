---
name: cart-addons-nesting
version: 1
description: Spec and guide for the hierarchical cart system, nested product/service add-ons, quantity boundary clamping, proportional scaling, and dynamic subtotal calculations.
---

# Cart & Add-ons Nesting Skill

Use this skill whenever working with, modifying, or porting cart domain models, parent-child add-on relations, quantity boundary rules, or total price calculations.

## Core Files
- `lib/core/cart/cart_models.dart`: `CartItem` and `CartAddOn` domain classes, clamping methods, and price getters.
- `lib/core/cart/cart_repository.dart`: Cart storage and signal management.
- `lib/features/cart/cart_bloc.dart`: Reactive signals and state operations.

## Fundamental Invariants
1. **Boundary Clamping**:
   $$\text{clampedQty} = \max(\text{minValue}, \min(\text{desiredQty}, \text{effectiveMax}))$$
   where $\text{effectiveMax} = \min(\text{maxValue}, \text{inventoryLevel} \text{ if present})$.
2. **Proportional Add-on Scaling**:
   When parent quantity changes from $Q_{\text{old}} \rightarrow Q_{\text{new}}$, scale add-ons by $Q_{\text{new}} / Q_{\text{old}}$ and clamp against add-on boundary limits.
3. **Availability Filtering**:
   Exclude items marked `OutOfStock`, `SoldOut`, or draft/deleted state from cart subtotal calculations.

## Documentation References
- Detailed Specification: `docs/02_cart_and_addons_spec.md`
- Data & Domain Architecture: `arch/02_data_and_domain.md`
- Porting Prompts: `prompts/02_cart_addons_porting_prompts.md`
