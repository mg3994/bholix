# Bholix Flutter Setup Report

Generated: 2026-06-10

---

## SKILL 1 — flutter-basic-setup

### Dependencies added to `pubspec.yaml`

**Runtime:**
- `drift: ^2.35.1` — SQLite ORM
- `drift_flutter: ^0.3.1` — Drift Flutter integration
- `flutter_localizations` (Flutter SDK) — i18n support
- `intl: ^0.20.3` — i18n formatting utilities
- `bloc_signals_flutter: ^1.3.2` — BLoC + signals state management
- `kaisel: ^1.1.0` — Custom UI toolkit
- `path_provider: ^2.1.6` — Platform path resolution

**Dev:**
- `build_runner: ^2.15.1`, `build: ^4.0.7`
- `build_web_compilers: ^4.8.5`
- `drift_dev: ^2.35.1`
- `kaisel_lint: ^0.5.1`

### Files created

| File | Purpose |
|---|---|
| `l10n.yaml` | ARB to Dart codegen config (class `AppLocalizations`, deferred loading) |
| `build.yaml` | Build runner: Drift codegen, dart2js for web worker, custom `copy_compiled_worker_js` |
| `analysis_options.yaml` | Lints: `flutter_lints` + `kaisel_lint/recommended`, platform dirs excluded |
| `devtools_options.yaml` | Enables Drift DevTools extension |
| `tools/builder.dart` | `CopyCompiledJs` build step — copies compiled `drift_worker.js` to `web/` |
| `tools/drift_worker.dart` | Dart entrypoint for the Drift web worker (compiled to JS) |
| `lib/l10n/app_en.arb` | Seed ARB file for English locale (`@@locale: en`) |

### sqlite3.wasm

Downloaded to `web/sqlite3.wasm` — 750,007 bytes (~732 KB).

---

## SKILL 2 — flutter-bootstrap-and-utilities

### Files created / overwritten

| File | Purpose |
|---|---|
| `lib/core/errors/reporter_impl.dart` | `BootstrapErrorReporter` abstraction: `noop` (const no-op) and `active` (buffers errors before reporter attaches, then flushes). |
| `lib/core/utils/sort_extension.dart` | `SchwartzianSortExtension<T>` on `Iterable<T>` — `sortedByExpensive` and `sortedByCompareExpensive` call the key function exactly once per element. |
| `lib/main.dart` | Bootstrap entry point: wires `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded` into `BootstrapErrorReporter.active()`. |

---

## SKILL 3 — flutter-scene-setup

### Dependency added

- `flutter_scene: ^0.24.0` added to `pubspec.yaml`

### `pubspec.yaml` flutter assets updated

Platform-specific asset bundles under `flutter_scene_generated/`:

| Path | Platforms |
|---|---|
| `flutter_scene_generated/` | all |
| `flutter_scene_generated/metal_ios/` | iOS |
| `flutter_scene_generated/metal_desktop/` | macOS |
| `flutter_scene_generated/opengl_es_vulkan/` | Android, Linux, Windows |
| `flutter_scene_generated/opengl_es/` | Web |

### Platform configs updated

- **Android** — `android/app/src/main/AndroidManifest.xml` present; build file is `android/app/build.gradle.kts`
- **iOS** — `ios/Runner/Info.plist` present
- **macOS** — `macos/Runner/Info.plist` present
- **Linux** — `linux/CMakeLists.txt` present
- **Windows** — `windows/CMakeLists.txt` present

### `hook/build.dart` created

Imports `flutter_scene/build_hooks.dart` and invokes `buildScenes` + `buildMaterials` via the Dart build hook system. This runs automatically before `flutter build` to compile `.glb`/material assets into platform-specific formats.

---

## Final `flutter pub get` result

Run: `flutter pub get` from project root.

**Result: success** (exit code 0)

Resolved all dependencies. 12 packages have newer versions that are incompatible with current constraints — these are upstream version availability notices only, not errors. Run `flutter pub outdated` for details.

**Warnings (informational only):**
- `_fe_analyzer_shared`, `analyzer`, `build_runner`, `build`, `build_web_compilers`, `dart_style`, `material_color_utilities`, `package_config`, `source_gen`, `vector_math`, `analysis_server_plugin`, `analyzer_plugin` all have newer versions available but are constrained by existing dependency ranges.

No dependency conflicts. Project is ready to build.
