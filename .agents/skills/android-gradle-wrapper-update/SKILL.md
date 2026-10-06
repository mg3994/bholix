---
name: android-gradle-wrapper-update
description: "Updates the Gradle wrapper distributionUrl in android/gradle/wrapper/gradle-wrapper.properties to the latest available stable Gradle version by scraping https://services.gradle.org/distributions/ and replacing the version in the -all.zip URL."
---

# Android Gradle Wrapper Update Skill

Use this skill when you need to update `android/gradle/wrapper/gradle-wrapper.properties` to the latest stable Gradle distribution.

## What This Skill Does

- Fetches the Gradle distributions listing from `https://services.gradle.org/distributions/`
- Parses all `gradle-X.Y.Z-all.zip` entries, filters out pre-releases, deduplicates, picks the highest stable version
- Updates the `distributionUrl` line in `android/gradle/wrapper/gradle-wrapper.properties`

## Full PowerShell Script (run entirely in one block from the project root)

> [!IMPORTANT]
> Always run this as a **single command block**. PowerShell variables do not persist across separate `execute_pwsh` calls — each call is a fresh process. Put everything (fetch + patch + verify) in one block.

```powershell
$ProgressPreference = 'SilentlyContinue'  # suppress verbose download progress output

# 1. Fetch distributions page and extract latest stable version
$page = Invoke-WebRequest -Uri "https://services.gradle.org/distributions/" -UseBasicParsing
$latestGradle = [regex]::Matches($page.Content, 'gradle-(\d+\.\d+(?:\.\d+)?)-all\.zip') |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_ -notmatch '(rc|milestone|alpha|beta|nightly)' } |
    Select-Object -Unique |
    Sort-Object {
        $parts = $_ -split '\.'
        $p2 = if ($parts.Count -gt 2) { [int]$parts[2] } else { 0 }
        [int]$parts[0] * 10000 + [int]$parts[1] * 100 + $p2
    } -Descending |
    Select-Object -First 1

Write-Host "Latest stable Gradle: $latestGradle"

# 2. Patch gradle-wrapper.properties
$propsPath = "android\gradle\wrapper\gradle-wrapper.properties"
$props = Get-Content $propsPath -Raw

# Regex matches the full distributionUrl line regardless of current version
$props = $props -replace 'distributionUrl=https\\:.*', "distributionUrl=https\://services.gradle.org/distributions/gradle-$latestGradle-all.zip"

Set-Content $propsPath $props -NoNewline

# 3. Verify
Write-Host "Updated:"
Get-Content $propsPath | Where-Object { $_ -match 'distributionUrl' }
```

## Expected Result

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.0-all.zip
```

## Important Notes

- **Single block execution is mandatory.** Variables assigned in one `execute_pwsh` call are not available in the next — always fetch and patch in the same block.
- **`$ProgressPreference = 'SilentlyContinue'`** must be set first to prevent verbose web-response progress lines from flooding the output.
- **Use integer-multiplier sort**, not `[version]` casting. `Sort-Object { [version]$_ }` with a script block emits `PSCustomObject` wrappers — string interpolation then gives an empty string. The integer approach (`major * 10000 + minor * 100 + patch`) is safe and sorts correctly (e.g. `9.10.0 > 9.9.0`).
- **Use `-all` variant** (includes sources and docs), not `-bin`.
- **`\:`** in the URL is intentional — Java `.properties` files require the colon to be backslash-escaped.
- **Stable only**: filter out `rc`, `milestone`, `alpha`, `beta`, `nightly` labels. Only pure `X.Y.Z` version strings.
- After updating, also run the `android-gradle-plugins-update` skill to ensure plugin versions are compatible with the new Gradle version.
