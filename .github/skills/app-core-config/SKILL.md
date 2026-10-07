---
name: app-core-config
version: 1
description: Explains the app's core configuration layer (lib/core/config, lib/core/errors, lib/core/utils). Use whenever adding new flavors, reading build mode, wiring error reporting at bootstrap, or using the Schwartzian sort extension.
---

# App core layer

Everything under `lib/core/` is shared infrastructure — no UI, no features. It covers three concerns: **app configuration** (flavor + build mode), **bootstrap error reporting**, and **collection utilities**.

---

## 1. Configuration (`lib/core/config/`)

### How the pieces fit together

```
FlavorInterface  (sealed const)
    └── Flavor (class, 3 static consts: development / staging / production)

BuildModeInterface  (sealed const)
    └── BuildMode (enum: debug / profile / release)

FlavorConfig<F, B>  (final class const)
    ├── .flavor   → F (FlavorInterface)
    └── .buildMode → B (BuildModeInterface)

AppFlavorConfig = FlavorConfig<Flavor, BuildMode>   ← concrete typedef

currentFlavor   → resolved at compile time from FLUTTER_APP_FLAVOR env var
currentFBConfig → const AppFlavorConfig (the single global config instance)
```

### Entry point — import

```dart
// Exposes everything you need in one line:
import 'core/config/config.dart';
// Exports: AppFlavorConfig, FlavorConfig, currentFBConfig, Flavor, FlavorInterface,
//          BuildMode (via BuildModeInterface part)
```

---

### `Flavor` — three environments, compile-time URL

`Flavor` is a `const` class with three singleton values. The active flavor is set **at build time** via `--dart-define=FLUTTER_APP_FLAVOR=<value>`.

```dart
// Accepted values for FLUTTER_APP_FLAVOR:
// 'dev' or 'development'  → Flavor.development
// 'stg' or 'staging'      → Flavor.staging
// anything else            → Flavor.production  (safe default)
```

**Base URL resolution order** (first match wins):

1. `--dart-define=SERVER_URL=https://…`  — overrides everything, all flavors
2. `Flavor._('staging', 'https://staging.api.com')` — custom URL passed to the private constructor
3. `http://localhost:8080` (desktop/web) or `http://10.0.2.2:8080` (Android emulator)

**Per-flavor defaults** — each returns a value the app can read from `currentFBConfig.flavor`:

| Property | development | staging | production |
|---|---|---|---|
| `defaultLocale` | `Locale('en')` | `Locale('en')` | `Locale('en')` |
| `defaultThemeMode` | `ThemeMode.system` | `ThemeMode.system` | `ThemeMode.system` |
| `defaultThemeSeedColor` | `Colors.blue` | `Colors.green` | `Colors.orange` |

These are **meant to be customised**. Each is a `switch (this)` so adding a new flavor without covering it is a compile error.

**Adding a custom base URL to a flavor:**

```dart
// In flavor.dart — use the private constructor's optional second arg:
static const Flavor staging = Flavor._('staging', 'https://api.staging.example.com');
```

---

### `BuildMode` — compile-time enum

`BuildMode` is an enum that implements `BuildModeInterface` (a sealed const class). `BuildMode.current` is evaluated at compile time from `kProfileMode` / `kReleaseMode` foundation constants — no runtime branch.

```dart
// Read the current build mode:
currentFBConfig.buildMode          // type: BuildMode (exhaustive in switch)

// Use in a switch expression safely:
final label = switch (currentFBConfig.buildMode) {
  BuildMode.debug   => 'dev',
  BuildMode.profile => 'profiling',
  BuildMode.release => 'release',
};
```

Because `AppFlavorConfig` types `B` concretely as `BuildMode`, the compiler knows the enum is exhaustive — no default branch needed.

---

### `FlavorConfig` — the bag that holds both

`FlavorConfig` is a `final const` generic class. It exposes convenience getters that forward to `flavor`:

```dart
currentFBConfig.baseUrl             // String
currentFBConfig.defaultThemeMode    // ThemeMode
currentFBConfig.defaultLocale       // Locale
currentFBConfig.defaultThemeSeedColor // Color
currentFBConfig.flavor              // Flavor (the enum-like class)
currentFBConfig.buildMode           // BuildMode (the enum)
```

The global singleton is `currentFBConfig`, a `const AppFlavorConfig`. Use it anywhere — it is safe to read before `runApp`.

---

### Common patterns

**Conditional logic by flavor:**

```dart
import 'core/config/config.dart';

if (currentFBConfig.flavor == Flavor.development) {
  // show debug banner, extra logging, etc.
}
```

**Conditional logic by build mode:**

```dart
switch (currentFBConfig.buildMode) {
  BuildMode.release => analyticsService.enable(),
  _                 => null,
};
```

**Passing to `MaterialApp`:**

```dart
MaterialApp(
  locale: currentFBConfig.defaultLocale,
  themeMode: currentFBConfig.defaultThemeMode,
  ...
)
```

**Building for a specific flavor:**

```sh
flutter run --dart-define=FLUTTER_APP_FLAVOR=development --enable-flutter-gpu
flutter run --dart-define=FLUTTER_APP_FLAVOR=staging
flutter build apk --dart-define=FLUTTER_APP_FLAVOR=production
```

---

### Adding a new flavor

1. Add a `static const Flavor` value in `flavor.dart`:
   ```dart
   static const Flavor beta = Flavor._('beta', 'https://beta.api.example.com');
   ```
2. Cover it in every `switch (this)` inside `Flavor` (compiler will flag any missing cases).
3. Add its string aliases to the `const` expression in `flavor_config.dart`:
   ```dart
   const Flavor currentFlavor = appFlavor == 'beta' ? Flavor.beta : ...;
   ```

---

## 2. Error reporting (`lib/core/errors/reporter_impl.dart`)

`BootstrapErrorReporter` solves a specific problem: errors can occur **before** a crash reporter (e.g. Firebase Crashlytics) has been initialised. The active variant queues those early errors and drains the queue the moment `attach()` is called.

### Two variants (factory constructors)

```dart
// No-op: all methods are empty. Use in tests or flavors that don't report.
const BootstrapErrorReporter.noop()

// Active: buffers errors until a real reporter is attached.
const BootstrapErrorReporter.active()
```

### Lifecycle

```dart
// 1. Create at bootstrap (before runApp):
final errorReporter = const BootstrapErrorReporter.active();

// 2. Wire Flutter's error handlers:
FlutterError.onError = (details) =>
    errorReporter.report(details.exception, details.stack ?? StackTrace.empty);

// 3. Later, once your crash service is ready, attach it:
//    Any errors buffered before this point are replayed immediately.
await CrashService.initialize();
errorReporter.attach((error, stack) => CrashService.record(error, stack));

// 4. On app teardown (optional but clean):
errorReporter.close();
```

### Rules

- `attach()` may only be called **once** — throws `StateError` on a second call.
- `attach()` throws if called after `close()`.
- `report()` after `close()` is silently ignored (safe).
- The static fields (`_reporter`, `_pending`, `_closed`) are class-level, so the `const` constructor works and every call to `const BootstrapErrorReporter.active()` shares the same state.

---

## 3. Collection utilities (`lib/core/utils/sort_extension.dart`)

`SchwartzianSortExtension` on `Iterable<T>` provides two methods that avoid repeated key computation during a sort (the **Schwartzian Transform**: decorate with key → sort → undecorate).

### When to use

Use over `.sorted()` or a custom comparator whenever the key function is **expensive** (a regex match, a DB lookup, a computed property with multiple steps). The key is evaluated **exactly once per element** — O(N) key calls, not O(N log N).

### Methods

```dart
// Key must implement Comparable<K> (String, int, double, DateTime, etc.)
List<T> sortedByExpensive<K extends Comparable<K>>(K Function(T) keyOf)

// Use when K is not Comparable or you need a custom ordering:
List<T> sortedByCompareExpensive<K>(K Function(T) keyOf, int Function(K, K) compare)
```

### Examples

```dart
import 'core/utils/sort_extension.dart';

// Sort files by their expensive-to-compute display name:
final sorted = files.sortedByExpensive((f) => f.computeDisplayName());

// Sort by a non-Comparable key (custom enum order):
final ranked = players.sortedByCompareExpensive(
  (p) => p.tier,
  (a, b) => tierRank(a).compareTo(tierRank(b)),
);
```

Both methods return a new `List<T>` — the original `Iterable` is not mutated.
