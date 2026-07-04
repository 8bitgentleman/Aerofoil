# Android build tooling modernization

The Android build was pinned to a 2020-era, internally inconsistent toolchain
(AGP 4.1.1 paired with Gradle 7.2, JCenter repositories, a JDK-11 requirement,
and an unpinned NDK). This change moves it to a current, mutually compatible
toolchain that builds end-to-end on Linux/CI as well as Android Studio.

## Version changes

| Component            | Before                     | After                          |
| -------------------- | -------------------------- | ------------------------------ |
| Android Gradle Plugin| 4.1.1                      | 8.6.1                          |
| Gradle wrapper       | 7.2                        | 8.7                            |
| JDK to run Gradle    | 11 (forced downgrade)      | 17                             |
| Dependency repos     | `jcenter()` + `google()`   | `google()` + `mavenCentral()`  |
| NDK                  | unpinned (whatever's local)| 26.3.11579264 (r26d), pinned   |
| `minSdkVersion`      | 16                         | 21                             |
| `APP_PLATFORM`       | android-16                 | android-21                     |
| Java source/target   | 8                          | 8 (unchanged)                  |
| `compileSdk`/`target`| 34 / 34                    | 34 / 34 (unchanged)            |

## Why these versions

- **AGP 8.6.1 + Gradle 8.7 + JDK 17** is a mutually supported, current-stable
  triple. AGP 8.6.x officially requires Gradle 8.7+ and JDK 17, and supports
  `compileSdk 34` with no warnings (AGP 8.7 begins nudging toward `compileSdk 35`,
  so 8.6.x is the cleaner fit while `compileSdk` stays at 34). We jumped straight
  from 4.1.1 to 8.6.1 rather than stepping through intermediate majors — the jump
  was verified by real builds (`assembleDebug` + `assembleRelease`), so stepping
  was unnecessary.
- **NDK r26d (26.3.11579264)** was chosen deliberately, not "latest". The latest
  LTS, r27, marks `ALooper_pollAll` as *unavailable* (a hard compile error), and
  the vendored `SDL2-2.30.5` still calls it in `SDL_androidsensor.c`. r26d is the
  newest NDK that compiles the vendored SDL unmodified, is an LTS release, and
  supports `minSdk 21`. Patching third-party SDL source was deliberately avoided
  as out of scope for a build-tooling change.
- **`mavenCentral()`** replaces `jcenter()`, which shut down in 2021.

## Behavior-relevant side effects

- **`minSdkVersion` 16 -> 21 (Android 4.1 -> 5.0).** This is a device-coverage
  change: devices on Android 4.1-4.4 (API 16-20) can no longer install the app.
  Those versions are collectively well under ~1% of active devices today. The
  bump is required because modern NDKs (r26/r27) no longer support API levels
  below 21 for the native libraries.
- **`namespace` moved into `app/build.gradle`.** AGP 8.x requires the `namespace`
  in the `android {}` block; the `package="org.thecodedeposit.aerofoil"` attribute
  (and the placeholder `versionCode="1"`/`versionName="1.0"`) were removed from
  `AndroidManifest.xml`. The applied package name and version are unchanged
  (`org.thecodedeposit.aerofoil`, versionCode 20, versionName 1.1.6) — verified in
  the built APK.
- **DSL renames for AGP 8.x:** `lintOptions {}` -> `lint {}` and
  `aaptOptions {}` -> `androidResources {}`. The `noCompress 'gpf'` custom-asset
  handling is preserved.
- No new R8/lint failures and no manifest-merger warnings surfaced in the build.
  (`minifyEnabled false` is unchanged, so R8 is not shrinking/obfuscating.)

## ABI filters

`armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64` were left as-is (not trimmed). Trimming
32-bit ABIs is a product/distribution decision, so it is flagged here rather than
made unilaterally.

## Native source symlinks on Linux/macOS

The native tree under `app/jni/` is assembled from repo-root sibling directories
via symlinks. Only `make_symlinks.bat` (Windows) existed; `make_symlinks.sh` /
`remove_symlinks.sh` were added for Linux/macOS/CI. The `.sh` version also creates
a repo-root `SDL2 -> SDL2-2.30.5` alias: several module `Android.mk` files use a
relative `../SDL2/include` include path, and on POSIX `../` from a *symlinked*
module directory is resolved physically (escaping to the real repo root) rather
than collapsed lexically as on Windows. That root alias is git-ignored.

## Verified

Built successfully with JDK 17 + Gradle 8.7 + AGP 8.6.1 + NDK r26d:
- `./gradlew assembleDebug` -> `app-debug.apk` (all 4 ABIs)
- `./gradlew assembleRelease` -> `app-release.apk` (all 4 ABIs)

The preserved 16 KB page-size alignment (`APP_LDFLAGS := -Wl,-z,max-page-size=16384`)
was confirmed in the output `.so` files (LOAD segment alignment = 0x4000).

## Preserved fixes

All four pre-existing fixes remain intact:
1. `RECEIVER_NOT_EXPORTED` flags on `registerReceiver` in `HIDDeviceManager.java`.
2. `APP_LDFLAGS` 16 KB alignment in `Application.mk`.
3. Removed `WRITE_EXTERNAL_STORAGE` permission.
4. `enableOnBackInvokedCallback` in `AndroidManifest.xml`.
