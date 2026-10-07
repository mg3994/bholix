---
name: android-gradle-plugins-update
description: "Updates the Android Gradle Plugin (com.android.application) and Kotlin Android plugin (org.jetbrains.kotlin.android) versions in android/settings.gradle.kts to the latest stable releases by querying Google Maven and Maven Central metadata XML. The dev.flutter.flutter-plugin-loader version is Flutter-managed and must NOT be changed."
---

# Android Gradle Plugins Update Skill

Use this skill when you need to update plugin versions in `android/settings.gradle.kts` to the latest stable releases.

## Target File

`android/settings.gradle.kts` — the `plugins { }` block:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}
```

## Plugin Rules

| Plugin ID | Source | Update? |
|---|---|---|
| `dev.flutter.flutter-plugin-loader` | Flutter SDK internal | **Never change** — Flutter manages this |
| `com.android.application` | Google Maven (AGP) | ✅ Update to latest stable |
| `org.jetbrains.kotlin.android` | Maven Central (JetBrains) | ✅ Update to latest stable |

---

## Full PowerShell Script (run entirely in one block from the project root)

> [!IMPORTANT]
> Always run this as a **single command block**. PowerShell variables do not persist across separate `execute_pwsh` calls — each call is a fresh process. Put everything (fetch AGP + fetch Kotlin + patch + verify) in one block.

```powershell
$ProgressPreference = 'SilentlyContinue'  # suppress verbose download progress output

# 1. Latest AGP from Google Maven metadata XML
$agpXml = [xml](Invoke-WebRequest -Uri "https://dl.google.com/dl/android/maven2/com/android/application/com.android.application.gradle.plugin/maven-metadata.xml" -UseBasicParsing).Content
$latestAgp = $agpXml.metadata.versioning.versions.version |
    Where-Object { $_ -match '^\d+\.\d+\.\d+$' } |
    Sort-Object {
        $parts = $_ -split '\.'
        [int]$parts[0] * 10000 + [int]$parts[1] * 100 + [int]$parts[2]
    } -Descending |
    Select-Object -First 1

# 2. Latest Kotlin from Maven Central metadata XML
$kotlinXml = [xml](Invoke-WebRequest -Uri "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/maven-metadata.xml" -UseBasicParsing).Content
$latestKotlin = $kotlinXml.metadata.versioning.versions.version |
    Where-Object { $_ -match '^\d+\.\d+\.\d+$' } |
    Sort-Object {
        $parts = $_ -split '\.'
        [int]$parts[0] * 10000 + [int]$parts[1] * 100 + [int]$parts[2]
    } -Descending |
    Select-Object -First 1

Write-Host "AGP: $latestAgp  |  Kotlin: $latestKotlin"

# 3. Patch settings.gradle.kts
$settingsPath = "android\settings.gradle.kts"
$settings = Get-Content $settingsPath -Raw

# Use [^"]* (zero-or-more) not [^"]+ (one-or-more) so the pattern also matches
# an accidentally-emptied version string "" (recovery-safe)
$settings = $settings -replace '(id\("com\.android\.application"\) version ")[^"]*(")', "`${1}$latestAgp`${2}"
$settings = $settings -replace '(id\("org\.jetbrains\.kotlin\.android"\) version ")[^"]*(")', "`${1}$latestKotlin`${2}"

# dev.flutter.flutter-plugin-loader is intentionally NOT touched

Set-Content $settingsPath $settings -NoNewline

# 4. Verify
Write-Host "Updated plugins block:"
($settings -split "`n") | Where-Object { $_ -match 'flutter-plugin-loader|com\.android|kotlin\.android' }
```

## Expected Result

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"       // unchanged
    id("com.android.application") version "9.4.1" apply false     // → latest AGP
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false // → latest Kotlin
}
```

---

## Important Notes

- **Single block execution is mandatory.** Variables assigned in one `execute_pwsh` call are not available in the next — always fetch both versions and apply in the same block.
- **`$ProgressPreference = 'SilentlyContinue'`** must be set first to prevent verbose web-response progress lines from flooding the output.
- **Use integer-multiplier sort**, not `[version]` casting. `Sort-Object { [version]$_ }` with a script block emits `PSCustomObject` wrappers — string interpolation then gives an empty string. The integer approach (`major * 10000 + minor * 100 + patch`) is safe and avoids this.
- **Use `[^"]*` (zero-or-more)** in the version replacement regex, not `[^"]+` (one-or-more). This makes the pattern resilient to a previously-emptied `""` version string (e.g. from a botched run), preventing the replacement from silently skipping the line.
- **Stable only**: the `^\d+\.\d+\.\d+$` filter keeps only pure `X.Y.Z` strings, excluding `-alpha`, `-beta`, `-rc`, `-SNAPSHOT`, `-Beta`, `-RC`.
- **Never change** `dev.flutter.flutter-plugin-loader` — Flutter's tooling manages this and changing it breaks the build.

## Compatibility Check

AGP and Kotlin versions must be compatible with each other and with the Gradle wrapper. Always cross-check:

- **AGP ↔ Gradle**: Check [AGP release notes](https://developer.android.com/build/releases/gradle-plugin) for the minimum Gradle version required by the AGP version you're targeting. Run the `android-gradle-wrapper-update` skill first (or after) to ensure the wrapper meets that minimum.
- **Kotlin ↔ AGP**: A newer Kotlin is generally safe alongside any AGP version.
- **Flutter**: Check the [Flutter Android Gradle migration guide](https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide) for any Flutter-specific constraints.

After updating, run `flutter build apk --debug` to confirm the build succeeds with the new versions.
