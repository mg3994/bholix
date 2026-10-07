---
name: flutter-scene-setup
description: "Provides comprehensive instructions and automated guidance for integrating `flutter_scene` and enabling Flutter GPU across all platforms (Android, iOS, macOS, Windows, Linux) in a Flutter project, including setting up build-time asset pipelines (`hook/build.dart`)."
---

# Flutter Scene & Flutter GPU Setup Skill

Use this skill when setting up `flutter_scene` in a Flutter project to ensure all platform-specific GPU flags and asset build hooks are correctly configured.

## Step 1: Add Dependency
Add `flutter_scene` to the project:
```bash
flutter pub add flutter_scene
```

## Step 2: Configure Android
In `android/app/src/main/AndroidManifest.xml`, inside the `<application>` tag, add the following meta-data:
```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableFlutterGPU"
    android:value="true" />
```

## Step 3: Configure iOS & macOS
In both `ios/Runner/Info.plist` and `macos/Runner/Info.plist`, inside the top-level `<dict>` tag, add:
```xml
<key>FLTEnableFlutterGPU</key>
<true/>
```

## Step 4: Configure Linux
In `linux/runner/my_application.cc`, right after `g_autoptr(FlDartProject) project = fl_dart_project_new();`, enable Flutter GPU:
```c
fl_dart_project_set_enable_flutter_gpu(project, TRUE);
```

## Step 5: Configure Windows
In `windows/runner/main.cpp`, right after `flutter::DartProject project(L"data");`, enable Flutter GPU:
```cpp
project.set_enable_flutter_gpu(true);
```

## Step 6: Set Up Asset Pipeline (`hook/build.dart`)
1. Create `hook/build.dart`:
```dart
import 'package:flutter_scene/build_hooks.dart';
// ignore: depend_on_referenced_packages
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    buildScenes(buildInput: input, buildOutput: output);
    await buildMaterials(buildInput: input, buildOutput: output);
  });
}
```

2. Add `flutter_scene_generated/` to `pubspec.yaml` under `flutter.assets`:
```yaml
flutter:
  uses-material-design: true
  generate: true
  assets:
    - flutter_scene_generated/
```

3. Run `flutter pub get` to resolve dependencies, then run the initialization CLI tool:
   ```bash
   flutter pub get
   dart run flutter_scene:init
   ```
   > [!NOTE]
   > When prompted during `dart run flutter_scene:init`, press `y` (Yes) to install or update the agent skills for `flutter_scene`.
