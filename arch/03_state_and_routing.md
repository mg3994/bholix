# 03 State & Routing Architecture

## Overview
`bholix` uses a lightweight, reactive state management model backed by `bloc_signals` and a type-safe, compile-time route definition model backed by `kaisel`.

---

## 1. Reactive State Management (`bloc_signals`)

State is managed through reactive signals and Bloc pattern components:

```
┌────────────────────────────────────────────────────────────┐
│                         CartBloc                           │
│  - cartItems: Signal<List<CartItem>>                       │
│  - add(CartItem item)                                      │
│  - updateQuantity(int index, int quantity)                 │
│  - remove(int index)                                       │
└─────────────────────────────┬──────────────────────────────┘
                              │ Re-evaluates
                              ▼
┌────────────────────────────────────────────────────────────┐
│                    Computed Quantities                     │
│  - totalItemCount: Computed<int>                           │
│  - subtotalPrice: Computed<double>                         │
└────────────────────────────────────────────────────────────┘
```

### Core Blocs:
* **`CartBloc` (`lib/features/cart/cart_bloc.dart`)**:
  Manages cart list, quantity clamping, add-on state updates, and price computations.
* **`GridBloc` (`lib/features/grid/grid_bloc.dart`)**:
  Manages feed pagination, search filtering, tag/category selection, and pull-to-refresh.
* **`LocationBloc` (`lib/features/location/location_bloc.dart`)**:
  Manages current user PIN code, geographic coordinates, location sheet state, and address selection.
* **`ProductBloc` (`lib/features/product/product_bloc.dart`)**:
  Manages selected variant attributes (e.g. Size, Color), selected service package, and add-on selections.

---

## 2. Type-Safe Hand-Written Routing (`kaisel`)

The routing layer (`lib/routing/app_router.dart`) uses sealed classes without reflection or code generation:

```
                  ┌──────────────────────┐
                  │      AppRoute        │ (sealed class)
                  └──────────┬───────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     ▼                       ▼                       ▼
GridRoute               ProductRoute            CartRoute
(category, query)       (postId, schema)        (sheet/page mode)
```

### Principles:
1. **No String Parsing Bugs**: Every route is represented as an immutable instance of `AppRoute`.
2. **Exhaustive Matching**: Route handling uses exhaustive `switch` expressions. Compiler guarantees all routes are handled.
3. **No Codegen Dependency**: Routing code is human-readable, fast to compile, and easy to port to pattern-matching languages (Swift `enum`, Rust `enum`, Kotlin `sealed class`).

---

## 3. Application Configuration & Bootstrap Error Architecture

Located in `lib/core/config/` and `lib/core/errors/`:

* **`FlavorConfig` (`lib/core/config/flavor_config.dart`)**:
  Compile-time `const` flavor & build mode definitions (`development`, `staging`, `production`).
* **`BootstrapErrorReporter` (`lib/core/errors/reporter_impl.dart`)**:
  Buffers errors during early startup before crash analytics services (e.g., Sentry / Crashlytics) are ready, then replays them synchronously when `attach()` is called.

---

## Portability Recommendations
* In Swift: Represent routes using `enum AppRoute` with associated values.
* In Kotlin: Represent routes using `sealed class AppRoute`.
* In TypeScript: Represent routes using discriminated unions (`type AppRoute = { kind: 'grid', query?: string } | ...`).
* For state management: Use native reactive signals/observables (e.g., `StateFlow` in Kotlin, `@Observable` in Swift, `signals` / `zustand` in React/TypeScript).
