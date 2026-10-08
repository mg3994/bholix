# Cross-Language Porting Guide

## Overview
This guide provides a step-by-step strategy for porting the `bholix` (Antinna Engine) codebase to alternative frameworks or programming languages (e.g., React Native/TypeScript, Swift/iOS, Kotlin/Android, Go/Backend).

---

## Technical Mapping Matrix

| Feature Subsystem | Dart / Flutter Original | TypeScript / React Native | Swift / SwiftUI | Kotlin / Android |
|---|---|---|---|---|
| **Dynamic Schema Maps** | `Map<String, dynamic>` | `Record<string, any>` | `[String: Any]` | `Map<String, Any?>` |
| **Reactive State** | `bloc_signals` | `signals` / `zustand` | `@Observable` / `Combine` | `StateFlow` / `LiveData` |
| **Sealed Routing** | `kaisel` | Discriminated Unions | `enum Route` | `sealed class Route` |
| **Local ORM / DB** | `Drift` (SQLite) | `WatermelonDB` / `SQLite` | `GRDB` / `CoreData` | `Room` |
| **HTTP Client** | `http` | `axios` / `fetch` | `URLSession` | `Retrofit` / `Ktor` |

---

## Step-by-Step Porting Blueprint

### Phase 1: Core Schema Engine & Utilities
1. Implement dynamic dictionary types (`JSONMap`).
2. Port `SchemaOverride`:
   - `resolveId(base, idValue) -> ResolvedId`
   - `deepMerge(target, source) -> Map`
   - `extractBase(schema)` and `extractDefaultLanguage(schema)`
3. Port `SchemaExtractor`:
   - `getLocalizedValue(val, locale, defaultLanguage)`
   - `extractJsonLd(html)` regex and unescaping.
   - `findMatchingVariant(...)` and property scoring.
   - Service and add-on tree walkers.

### Phase 2: Cart Domain & Boundary Math
1. Define `CartItem` and `CartAddOn` data structures.
2. Implement boundary clamping:
   - Calculate `effectiveMax = min(maxValue, inventoryLevel ?? maxValue)`.
   - `clampedQuantity = max(minValue, min(desiredQty, effectiveMax))`.
3. Implement proportional add-on scaling:
   - When parent quantity updates from $Q_{old} \rightarrow Q_{new}$, scale add-ons by $Q_{new} / Q_{old}$ and clamp against individual add-on limits.
4. Implement cart subtotal calculation, excluding unavailable items (`OutOfStock`, `SoldOut`).

### Phase 3: External Services & APIs
1. Implement `AppsScriptService`: `createOrder` POST endpoint and `getPlaceSuggestions` GET endpoint.
2. Implement `PaymentService`: UPI URI generator (`upi://pay?...`).
3. Implement `GeoVerificationService`: Indian PIN code regex validation (`^[1-9][0-9]{5}$`) and Schema.org `ParcelDelivery` generator.
4. Implement `PhoneVerificationService`: E.164 phone formatting and OTP workflow state machine.

### Phase 4: State Management & UI Layer
1. Map reactive signals (Cart, Grid, Location, Product) to target framework state management primitives.
2. Map sealed routes to navigation routing containers.
3. Construct UI screens/views (Product details, Variant selectors, Add-on cards, Cart sheet, Checkout flow) conforming to design system token values.

---

## Code Snippet Comparison: Clamping Quantity

### TypeScript:
```typescript
export function clampedQuantity(desired: number, minVal: number = 1, maxVal: number = 99, inventory?: number): number {
  const effectiveMax = inventory !== undefined ? Math.min(maxVal, inventory) : maxVal;
  return Math.max(minVal, Math.min(desired, effectiveMax));
}
```

### Swift:
```swift
func clampedQuantity(desired: Int, minValue: Int = 1, maxValue: Int = 99, inventory: Int? = nil) -> Int {
    let effectiveMax = inventory != nil ? min(maxValue, inventory!) : maxValue
    return max(minValue, min(desired, effectiveMax))
}
```

### Kotlin:
```kotlin
fun clampedQuantity(desired: Int, minValue: Int = 1, maxValue: Int = 99, inventory: Int? = null): Int {
    val effectiveMax = inventory?.let { minOf(maxValue, it) } ?: maxValue
    return desired.coerceIn(minValue, effectiveMax)
}
```
