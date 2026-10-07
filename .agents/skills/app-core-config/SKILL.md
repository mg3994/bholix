---
name: app-core-config
version: 2
description: Explains the app's core configuration layer (lib/core/config, lib/core/errors, lib/core/utils). Use whenever adding new flavors, reading build mode, wiring error reporting at bootstrap, or using the Schwartzian sort extension. Everything in this layer is compile-time const — no runtime allocation, no mutable state in the config path.
---

# App core layer

Everything under `lib/core/` is shared infrastructure — no UI, no features. Three concerns: **app configuration** (flavor + build mode), **bootstrap error reporting**, and **collection utilities**.

**The one thing to internalize: the entire config stack is `const` all the way down.** `FlavorInterface`, `BuildModeInterface`, `FlavorConfig`, the three `Flavor` singletons, `BuildMode.current`, and `currentFBConfig` are all compile-time constants. No factory, no `late`, no `getInstance()`. Read `currentFBConfig` anywhere — even before `runApp` — with zero overhead.

---

## 1. Configuration (`lib/core/config/`)

### The const chain — how every piece fits

```
sealed const class FlavorInterface          ← contract (part of flavor.dart)
    └── const class Flavor implements FlavorInterface
            ├── static const Flavor.development
            ├── static const Flavor.staging
            └── static const Flavor.production

sealed const class BuildModeInterface       ← contract (build_mode_interface.dart)
    └── enum BuildMode implements BuildModeInterface   (part file)
            ├── debug
            ├── profile
            ├── release
            └── static const BuildMode.current  ← compile-time, no runtime branch

final const class FlavorConfig<F extends FlavorInterface, B extends BuildModeInterface>
    ├── required final F flavor
    └── required final B buildMode

typedef AppFlavorConfig = FlavorConfig<Flavor, BuildMode>  ← concrete, exhaustive

const Flavor      currentFlavor   ← resolved from --dart-define=FLUTTER_APP_FLAVOR
const AppFlavorConfig currentFBConfig = FlavorConfig(
  flavor: currentFlavor,
  buildMode: BuildMode.current,
)
```

Every node in this chain is `const`. Adding a `new` or a non-const constructor anywhere breaks the invariant — the compiler will catch it.

### Import

```dart
// One import exposes the whole config surface:
import 'core/config/config.dart';
// Exports: FlavorConfig, AppFlavorConfig, currentFBConfig,
//          Flavor, FlavorInterface, BuildModeInterface, BuildMode
```

---

### `FlavorInterface` — the sealed const contract

```dart
// flavor_interface.dart  (part of flavor.dart)
sealed class const FlavorInterface() {
  String get name;
  String get baseUrl;
  ThemeMode get defaultThemeMode;
  Locale get defaultLocale;
  Color get defaultThemeSeedColor;
}
```

`sealed` means the compiler knows every subtype. `const` means any implementor must be constructible as a compile-time constant. Never add a non-const field or a mutable getter here.

---

### `Flavor` — three compile-time singletons

```dart
// Declared with a private const constructor so only the three
// named constants can ever exist — no external instantiation.
class Flavor implements FlavorInterface {
  const Flavor._(this.name, [this._customUrl]);

  static const Flavor development = Flavor._('development');
  static const Flavor staging     = Flavor._('staging');
  static const Flavor production  = Flavor._('production');
  ...
}
```

**Base URL resolution** — first match wins, evaluated at runtime of `baseUrl` getter:

1. `--dart-define=SERVER_URL=https://…` → overrides all flavors
2. `_customUrl` set in the private constructor → `Flavor._('staging', 'https://...')`
3. Fallback: `http://10.0.2.2:8080` on Android emulator, `http://localhost:8080` everywhere else

**Per-flavor defaults:**

| Property | development | staging | production |
|---|---|---|---|
| `defaultLocale` | `Locale('en')` | `Locale('en')` | `Locale('en')` |
| `defaultThemeMode` | `ThemeMode.system` | `ThemeMode.system` | `ThemeMode.system` |
| `defaultThemeSeedColor` | `Colors.blue` | `Colors.green` | `Colors.orange` |

Each is a `switch (this)` expression — adding a new `Flavor` constant without covering it is a **compile error**. Never use `default:` in these switches; exhaustiveness is the point.

**Adding a custom server URL:**

```dart
// flavor.dart — second arg to the private constructor:
static const Flavor staging = Flavor._('staging', 'https://api.staging.example.com');
```

---

### `BuildMode` — compile-time enum

```dart
// build_mode.dart  (part of build_mode_interface.dart)
enum BuildMode() implements BuildModeInterface {
  debug, profile, release;

  static const BuildMode current =
      kProfileMode ? BuildMode.profile :
      kReleaseMode ? BuildMode.release :
                     BuildMode.debug;
}
```

`BuildMode.current` is a compile-time constant — the ternary on `kProfileMode`/`kReleaseMode` collapses at compile time. There is no `if` at runtime.

```dart
// Exhaustive switch — no default needed because AppFlavorConfig
// types B as BuildMode, so the compiler sees all three cases:
final label = switch (currentFBConfig.buildMode) {
  BuildMode.debug   => 'debug',
  BuildMode.profile => 'profile',
  BuildMode.release => 'release',
};
```

---

### `FlavorConfig` — the immutable config bag

```dart
// flavor_config.dart
final class const FlavorConfig<
  F extends FlavorInterface,
  B extends BuildModeInterface
>({required final F flavor, required final B buildMode}) {
  String   get baseUrl              => flavor.baseUrl;
  ThemeMode get defaultThemeMode    => flavor.defaultThemeMode;
  Locale   get defaultLocale        => flavor.defaultLocale;
  Color    get defaultThemeSeedColor => flavor.defaultThemeSeedColor;
}
```

`final class` — cannot be subclassed. `const` primary constructor — every instance is a compile-time constant when its arguments are const (they always are). All getters delegate to `flavor`, which is itself const.

**The global instance:**

```dart
const AppFlavorConfig currentFBConfig = FlavorConfig(
  flavor: currentFlavor,    // const Flavor
  buildMode: BuildMode.current, // const BuildMode
);
```

Read from anywhere without injection, service locators, or singletons:

```dart
currentFBConfig.baseUrl
currentFBConfig.defaultThemeMode
currentFBConfig.defaultLocale
currentFBConfig.defaultThemeSeedColor
currentFBConfig.flavor        // Flavor
currentFBConfig.buildMode     // BuildMode
```

---

### Common patterns

**Gate on flavor:**

```dart
if (currentFBConfig.flavor == Flavor.development) {
  // debug banner, verbose logging, etc.
}
```

**Gate on build mode:**

```dart
if (currentFBConfig.buildMode == BuildMode.release) {
  analyticsService.enable();
}
```

**Pass into `MaterialApp`:**

```dart
MaterialApp(
  locale: currentFBConfig.defaultLocale,
  themeMode: currentFBConfig.defaultThemeMode,
  color: currentFBConfig.defaultThemeSeedColor,
)
```

**Build commands — choosing between `--flavor` and `--dart-define`:**

Flutter supports two ways to select a flavor. They are **not interchangeable across platforms**.

`--flavor` is a native build-system concept. On Android it maps to a Gradle product flavor; on iOS/macOS it maps to an Xcode scheme. It passes the name through the native toolchain so platform-level build configs (signing, app IDs, icons) can differ per flavor. **Web has no native build system, so `--flavor` is silently ignored on `flutter build web` and `flutter run -d chrome`** — the flag is accepted but does nothing.

`--dart-define=FLUTTER_APP_FLAVOR=` sets a compile-time Dart constant that is read directly in `flavor_config.dart`. It works on every platform including web.

| Platform | Prefer | Why |
|---|---|---|
| Android | `--flavor` | wires into Gradle product flavors, app IDs, signing configs |
| iOS / macOS | `--flavor` | wires into Xcode schemes and build configurations |
| Web | `--dart-define=FLUTTER_APP_FLAVOR=` | `--flavor` is ignored on web, this is the only working option |
| Linux / Windows | `--dart-define=FLUTTER_APP_FLAVOR=` | no native flavor concept on these targets |

Both flags can be combined: `--flavor` drives the native toolchain; `--dart-define` drives the Dart constant. For native targets you typically use both together so the Dart code and the native build config agree.

```sh
# Native targets — both flags together:
flutter run  --flavor development --dart-define=FLUTTER_APP_FLAVOR=development --enable-flutter-gpu
flutter run  --flavor staging     --dart-define=FLUTTER_APP_FLAVOR=staging
flutter build apk --flavor production --dart-define=FLUTTER_APP_FLAVOR=production

# Web — dart-define only (--flavor is ignored):
flutter run  -d chrome --dart-define=FLUTTER_APP_FLAVOR=development --enable-flutter-gpu
flutter build web      --dart-define=FLUTTER_APP_FLAVOR=production

# SERVER_URL overrides baseUrl on any platform / flavor:
flutter run  --flavor development --dart-define=FLUTTER_APP_FLAVOR=development \
             --dart-define=SERVER_URL=https://dev.api.example.com --enable-flutter-gpu
```

---

### Adding a new flavor — checklist

```dart
// 1. Add the const singleton in flavor.dart:
static const Flavor beta = Flavor._('beta', 'https://beta.api.example.com');

// 2. Cover it in every switch(this) in Flavor — compiler enforces this.
//    Example: defaultThemeSeedColor
Color get defaultThemeSeedColor => switch (this) {
  Flavor.development => Colors.blue,
  Flavor.staging     => Colors.green,
  Flavor.beta        => Colors.purple,  // ← new
  _                  => Colors.orange,
};

// 3. Add the dart-define alias in flavor_config.dart:
const Flavor currentFlavor =
    appFlavor == 'dev'  || appFlavor == 'development' ? Flavor.development :
    appFlavor == 'stg'  || appFlavor == 'staging'     ? Flavor.staging     :
    appFlavor == 'beta'                               ? Flavor.beta        :
                                                        Flavor.production;
```

---

## 2. Error reporting (`lib/core/errors/reporter_impl.dart`)

`BootstrapErrorReporter` solves one problem: errors happen **before** a crash service (e.g. Firebase Crashlytics) is ready. The active variant queues them and drains the queue the instant `attach()` is called.

### Two const factory constructors

```dart
// No-op — every method is empty. Use in tests or non-reporting flavors:
const BootstrapErrorReporter.noop()

// Active — buffers errors, drains on attach():
const BootstrapErrorReporter.active()
```

Both are `const`. The `_ActiveBootstrapErrorReporter` stores its mutable state in `static` fields so the `const` constructor requirement is satisfied — the instance itself is stateless, the shared class-level state holds the buffer.

### Lifecycle

```dart
// ① Before runApp — create and wire Flutter's global error handler:
const errorReporter = BootstrapErrorReporter.active();

FlutterError.onError = (details) =>
    errorReporter.report(details.exception, details.stack ?? StackTrace.empty);

PlatformDispatcher.instance.onError = (error, stack) {
  errorReporter.report(error, stack);
  return true;
};

// ② After crash service initialises — attach the real sink.
//    All buffered errors are replayed synchronously here.
await CrashService.initialize();
errorReporter.attach((error, stack) => CrashService.record(error, stack));

// ③ On teardown (optional):
errorReporter.close();
```

### Rules — read before calling attach()

- `attach()` exactly **once**. A second call throws `StateError('Error reporter is already attached.')`.
- `attach()` after `close()` throws `StateError('Error reporter is closed.')`.
- `report()` after `close()` is a silent no-op — safe.
- `const BootstrapErrorReporter.active()` anywhere in the app always refers to the **same static state** — it behaves like a true singleton even though the constructor is `const`.

---

## 3. Collection utilities (`lib/core/utils/sort_extension.dart`)

`SchwartzianSortExtension<T>` on `Iterable<T>` avoids calling an expensive key function more than once per element during a sort.

### Why this matters — the sum-of-N analogy

Think of summing the numbers 1 through N.

```dart
// Naive — O(N): visits every number
int sum = 0;
for (int i = 1; i <= n; i++) {
  sum += i;         // key function called N times
}

// Formula — O(1): one expression, no loop
final int sum = n * (n + 1) ~/ 2;  // key function called exactly once
```

A standard Dart `.sorted((a, b) => expensiveKey(a).compareTo(expensiveKey(b)))` is the loop version: the comparator is called **O(N log N)** times, so `expensiveKey` is also called O(N log N) times.

`sortedByExpensive` is the formula version: it calls `expensiveKey` exactly **O(N)** times — once per element — then sorts the cached pairs, then strips the keys. Same result, far fewer key evaluations when the key is expensive.

```dart
// O(N log N) key calls — naïve:
files.sorted((a, b) => a.computeDisplayName().compareTo(b.computeDisplayName()));
//           ↑ computeDisplayName() called O(N log N) times

// O(N) key calls — Schwartzian:
files.sortedByExpensive((f) => f.computeDisplayName());
//                       ↑ computeDisplayName() called exactly N times
```

For a cheap key (field access, integer comparison) the difference is invisible. For an expensive key (regex, DB read, multi-step computation) it is the difference between a stutter and a fast pass.

### Methods

```dart
// K must be Comparable (String, int, double, DateTime, …):
List<T> sortedByExpensive<K extends Comparable<K>>(K Function(T) keyOf)

// K is not Comparable, or you need a custom ordering:
List<T> sortedByCompareExpensive<K>(
  K Function(T) keyOf,
  int Function(K a, K b) compare,
)
```

### Examples

```dart
import 'core/utils/sort_extension.dart';

// Sort by a string key computed once per file:
final sorted = files.sortedByExpensive((f) => f.computeDisplayName());

// Sort by a custom enum rank:
final ranked = players.sortedByCompareExpensive(
  (p) => p.tier,
  (a, b) => tierRank(a).compareTo(tierRank(b)),
);
```

Both methods return a **new** `List<T>` — the source `Iterable` is never mutated.
