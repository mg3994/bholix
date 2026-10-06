---
name: flutter-basic-setup
description: "Provides standardized boilerplate and configuration templates for a new Flutter project including standard dependencies, dev_dependencies, l10n.yaml, build.yaml (Drift and worker compilation), analysis_options.yaml, devtools_options.yaml, and Drift WASM web worker tools and sqlite3.wasm asset."
---

# Flutter Basic Project Setup Skill

Use this skill when setting up a new project with the project's standard architecture, dependencies, localization settings, build-runner configurations, DevTools options, and Drift WASM web worker tools and `sqlite3.wasm`.

> [!IMPORTANT]
> **Always use the CLI to add packages and dependencies!**
> Do not manually edit `pubspec.yaml` to add packages or dependencies. Always use the command line interface:
> - SDK packages (e.g., `flutter_localizations`) must be added as a separate command:
>   `flutter pub add flutter_localizations --sdk=flutter`
> - Normal dependencies (without version constraints so `pub` resolves the latest compatible versions):
>   `flutter pub add <package_name_1> <package_name_2> ...`
> - Dev dependencies (without version constraints):
>   `flutter pub add --dev <dev_package_name_1> <dev_package_name_2> ...`

## 1. Dependencies & Dev Dependencies (`pubspec.yaml`)

Run the following CLI commands to add the required packages:

```bash
# Add SDK dependency (separate command)
flutter pub add flutter_localizations --sdk=flutter

# Add third-party dependencies (no explicit version constraints)
flutter pub add intl bloc_signals_flutter drift drift_flutter kaisel path_provider

# Add dev dependencies (no explicit version constraints)
flutter pub add --dev build build_runner build_web_compilers drift_dev kaisel_lint
```

Reference structure in `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl:
  bloc_signals_flutter:
  drift:
  drift_flutter:
  kaisel:
  path_provider:

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints:
  build:
  build_runner:
  build_web_compilers:
  drift_dev:
  kaisel_lint:
```

## 2. Localization Configuration (`l10n.yaml`)

Create `l10n.yaml` in the project root:

```yaml
arb-dir: lib/l10n
output-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getters: false
untranslated-messages-file: lib/l10n/untranslated.json
use-escaping: false
use-deferred-loading: true
relax-syntax: true
required-resource-attributes: false
preferred-supported-locales:
  - en
```

And create `lib/l10n/app_en.arb`:
```json
{
    "@@locale":"en"
}
```

## 3. Build & Drift Configuration (`build.yaml`)

Create `build.yaml` in the project root:

```yaml
targets:
  $default:
    sources:
      - lib/**
      - web/**
      - tools/**
      - $package$
      - lib/$lib$
      - pubspec.yaml
      - "!build/**"
      - "!**/build/**"
      - "!**/generated/**"
    builders:
      drift_dev:
        options:
          databases:
            default: lib/src/storage/drift/app_database.dart
          sql:
            dialect: sqlite
            options:
              version: "3.38"
              modules:
                - fts5
      build_web_compilers:entrypoint:
        generate_for:
          - tools/drift_worker.dart
        options:
          compiler: dart2js
        dev_options:
          dart2js_args:
            - --no-minify
        release_options:
          dart2js_args:
            - -O4
      ":copy_compiled_worker_js":
        enabled: true

builders:
  copy_compiled_worker_js:
    import: "tools/builder.dart"
    builder_factories: ["CopyCompiledJs.new"]
    required_inputs:
      - .js
    build_to: source
    build_extensions:
      "tools/drift_worker.dart": ["web/drift_worker.js"]
```

## 4. Linting Configuration (`analysis_options.yaml`)

Configure `analysis_options.yaml` in the project root (ensure the plugin version matches the latest `kaisel_lint` version in `pubspec.yaml`):

```yaml
include:
  - package:flutter_lints/flutter.yaml
  - package:kaisel_lint/recommended.yaml

plugins:
  kaisel_lint:
    version: ^0.5.1 # Always specify the latest version matching pubspec.yaml
    diagnostics:
      prefer_const_route_constructors: true
      prefer_pattern_match_over_is_check: true
      unused_guard_redirect: true
      prefer_push_or_replace_top_in_adaptive: false
```

## 5. DevTools Configuration (`devtools_options.yaml`)

Create `devtools_options.yaml` in the project root to enable Flutter DevTools extensions (such as Drift inspection):

```yaml
extensions:
  - drift: true
```

## 6. Drift WASM Web Worker, Custom Builder (`tools/`) & `sqlite3.wasm` (`web/`)

- Ensure `web/sqlite3.wasm` is present in the `web/` directory for SQLite WebAssembly support in Drift. Please download the `sqlite3.wasm` file from the official Drift releases page: [https://github.com/simolus3/drift/releases](https://github.com/simolus3/drift/releases) (download `sqlite3.wasm` from the latest release assets and place it in `web/sqlite3.wasm`).
- `tools/builder.dart`:
```dart
import 'package:build/build.dart';

class CopyCompiledJs extends Builder {
  // ignore: unnecessary_type_name_in_constructor, avoid_unused_constructor_parameters
  CopyCompiledJs([BuilderOptions? options]);

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = buildStep.allowedOutputs.single;
    final compiledId = AssetId(inputId.package, '${inputId.path}.js');

    final compiledWorker = await buildStep.readAsBytes(compiledId);
    await buildStep.writeAsBytes(outputId, compiledWorker);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    'tools/drift_worker.dart': ['web/drift_worker.js'],
  };
}
```

- `tools/drift_worker.dart`:
```dart
import 'package:drift/wasm.dart';

/// This Dart program is the entrypoint of a web worker that will be compiled to
/// JavaScript by running `build_runner build`.
void main() {
  return WasmDatabase.workerMainForOpen();
}
```
