---
name: github-actions-flutter-build-release
description: "Provides the standard GitHub Actions workflow template for Flutter projects: build_runner code generation, multi-platform builds (APK, AAB, IPA, Web, Linux, Windows, macOS), GitHub Releases upload, and GitHub Pages web deployment. Runs on macOS by default; Linux/Windows builds automatically switch to their required runners."
---

# GitHub Actions Flutter Build & Release Skill

Use this skill when setting up or updating the CI/CD pipeline for a Flutter project. The workflow lives at `.github/workflows/build-release.yml`.

## Action Versions (as of October 2026)

Always use the latest major version tags. Do **not** invent version numbers — verify at the linked release pages.

| Action | Latest major | Release page |
|---|---|---|
| `actions/checkout` | `v7` | https://github.com/actions/checkout/releases |
| `actions/setup-java` | `v6` | https://github.com/actions/setup-java/releases |
| `subosito/flutter-action` | `v2` | https://github.com/subosito/flutter-action/releases |
| `actions/upload-artifact` | `v7` | https://github.com/actions/upload-artifact/releases |
| `actions/download-artifact` | `v4` | https://github.com/actions/download-artifact/releases |
| `softprops/action-gh-release` | `v3` | https://github.com/softprops/action-gh-release/releases |
| `actions/configure-pages` | `v6` | https://github.com/actions/configure-pages/releases |
| `actions/upload-pages-artifact` | `v5` | https://github.com/actions/upload-pages-artifact/releases |
| `actions/deploy-pages` | `v5` | https://github.com/actions/deploy-pages/releases |

> [!IMPORTANT]
> When applying this skill, **always fetch** the release pages above to confirm the latest major version before writing the workflow. Action versions move faster than this document.

---

## Workflow Behaviour

| Trigger | Default build target | Default Flutter channel |
|---|---|---|
| `push` (any branch) | `apk` | `stable` (from `env.FLUTTER_CHANNEL`) |
| `pull_request` (any branch) | `apk` | `stable` |
| `workflow_dispatch` (manual) | User-selected dropdown, default `apk` | User-selected dropdown, default `stable` |

### Manual dispatch inputs
- **`build_target`**: `apk` · `appbundle` · `ipa` · `web` · `linux` · `windows` · `macos` · `all`
- **`flutter_channel`**: `stable` · `beta` · `master`
- **`web_renderer`**: `canvaskit` · `html` · `skwasm` · `auto`  (only affects web builds)

### Runner selection
| Target | Runner | Reason |
|---|---|---|
| `apk`, `appbundle`, `ipa`, `web`, `macos` | `macos-latest` | Default; required for iOS/macOS codesign toolchain |
| `linux` | `ubuntu-latest` | GTK toolchain not available on macOS runners |
| `windows` | `windows-latest` | MSVC toolchain required |

### Release & deploy rules
- Artifacts uploaded for **every run** on **every branch**, 30-day retention.
- GitHub Release (`softprops/action-gh-release`) created/updated **only on `main`/`master`**, tagged `build-<run_number>`.
- GitHub Pages deployment runs **only on `main`/`master`** after a successful web build, in a separate `deploy-pages` job.

---

## Top-level `env` block

```yaml
env:
  FLUTTER_VERSION: ""          # Empty = latest on channel. Pin e.g. "3.32.0" for reproducible builds.
  FLUTTER_CHANNEL: "stable"    # Default for push/PR. Manual dispatch overrides via input dropdown.
  WEB_RENDERER: "canvaskit"    # Default web renderer for push/PR. Options: canvaskit | html | skwasm | auto
  JAVA_VERSION: "17"
  JAVA_DISTRIBUTION: "temurin"
```

- `FLUTTER_CHANNEL` controls the default for automated triggers (push, PR). The manual dispatch `flutter_channel` input overrides it.
- `WEB_RENDERER` controls the default web renderer for push/PR web builds. The manual dispatch `web_renderer` input overrides it. Valid values: `canvaskit` (default, pixel-perfect), `html` (smaller bundle), `skwasm` (multi-threaded Wasm, best performance), `auto` (Flutter picks based on browser).
- `FLUTTER_VERSION` is forwarded to `subosito/flutter-action`. Leave empty to track the latest on the chosen channel, or pin to lock the SDK.
- `JAVA_DISTRIBUTION` must be `temurin`. Never use `zulu` or `adopt` (both deprecated).

---

## Channel propagation pattern

The `resolve` job reads the manual input (or falls back to `env.FLUTTER_CHANNEL`) and broadcasts it as an output:

```yaml
# In the resolve job
echo "channel=$CHANNEL" >> "$GITHUB_OUTPUT"
```

Every build job reads it:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: ${{ env.FLUTTER_VERSION }}
    channel: ${{ needs.resolve.outputs.channel }}
    cache: true
```

This is the **only** correct pattern. Do not hardcode a channel string in individual jobs.

---

## Key Design Decisions

### `build_runner` before every Flutter build
```yaml
- name: Run build_runner
  run: dart run build_runner build --release --delete-conflicting-outputs
```
`--delete-conflicting-outputs` prevents stale generated file conflicts in CI. Always runs before `flutter build`.

### Java only for Android targets
`actions/setup-java@v6` is included only in jobs that build Android targets (`apk`, `appbundle`). iOS, web, macOS, Linux, and Windows jobs don't need it.

### `concurrency` block
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```
Cancels queued runs on the same branch when a newer push arrives, saving runner minutes.

### Web renderer
```yaml
flutter build web --release --web-renderer ${{ needs.resolve.outputs.web_renderer }}
```
The renderer is resolved from the `web_renderer` dispatch input (default `canvaskit`) or `env.WEB_RENDERER` for push/PR triggers. Never hardcode the renderer string in the build step — always read it from the `resolve` output.

**Renderer guide:**
| Renderer | Best for |
|---|---|
| `canvaskit` | Pixel-perfect fidelity matching native, moderate bundle size (~1.5 MB) |
| `skwasm` | Best runtime performance via multi-threaded WebAssembly (requires SharedArrayBuffer / COOP+COEP headers) |
| `html` | Smallest bundle, uses browser DOM — lower fidelity, good for content-heavy apps |
| `auto` | Flutter picks `canvaskit` or `html` based on browser capabilities at runtime |

### IPA without code signing
```yaml
flutter build ipa --release --no-codesign
```
Produces a distributable `.ipa` for CI without Apple certificate secrets. Add Fastlane or `ios-deploy` steps when real distribution signing is needed.

### Linux system dependencies
```yaml
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev
```
Required for `flutter build linux`. Missing any of these causes an opaque CMake error with no clear root cause.

### GitHub Pages permissions
```yaml
permissions:
  pages: write
  id-token: write
```
These are required on the `deploy-pages` job. Without `id-token: write`, OIDC token creation fails and the deployment is rejected.

---

## Artifact Paths by Target

| Target | Output path | Packaged as |
|---|---|---|
| APK | `build/app/outputs/flutter-apk/app-release.apk` | raw file |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | raw file |
| IPA | `build/ios/ipa/*.ipa` | raw file |
| Web | `build/web/` | directory (uploaded as-is to Pages) |
| Linux | `build/linux/x64/release/bundle/` | `bholix-linux.tar.gz` |
| Windows | `build\windows\x64\runner\Release\` | `bholix-windows.zip` |
| macOS | `build/macos/Build/Products/Release/bholix.app` | `bholix-macos.zip` |

---

## One-time Repository Setup

1. **Enable GitHub Pages**: Settings → Pages → Source → **GitHub Actions**
2. **Workflow permissions**: Settings → Actions → General → Workflow permissions → **Read and write permissions** (required by `softprops/action-gh-release` to create releases and tags)

---

## Extending the Workflow

| Need | How |
|---|---|
| Code signing (Android) | Add keystore secret steps before `flutter build apk` |
| Code signing (iOS) | Replace `--no-codesign` with a Fastlane lane or `apple-actions/import-codesign-certs` |
| Run tests | Add `flutter test` between `flutter pub get` and `dart run build_runner build` |
| Rename app in artifact filenames | Search-replace `bholix` in the workflow file |
| Staging Pages environment | Duplicate `deploy-pages`, target a different branch, use a different environment name |
| Lock Flutter version | Set `FLUTTER_VERSION: "3.32.0"` in the `env` block |
