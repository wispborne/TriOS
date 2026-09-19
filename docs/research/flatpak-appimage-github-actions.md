# Flatpak and AppImage builds for TriOS in GitHub Actions

Researched 2026-09-13. Sources are official docs, specs, and source code. Every claim links to where it comes from. Nothing here has been tried on a real build yet.

## Short answer

- **AppImage is the easy one.** TriOS already builds a Linux bundle on `ubuntu-22.04`. Turning that bundle into an AppImage is one extra job step plus a `.desktop` file and an icon. The workflow part is about a day of work.
- **A `.flatpak` file attached to GitHub releases is medium effort.** The build is simple if it reuses the Linux bundle CI already makes. The hard part is the sandbox. TriOS has to reach a game folder anywhere on disk, run the game's own Java, and see the game's process. Each of those needs a permission or a workaround, and the game itself may not run properly inside the sandbox (see [Game launch inside the sandbox](#game-launch-inside-the-flatpak-sandbox)).
- **Publishing on Flathub is a large, open-ended job.** Flathub requires building from source with no network access. TriOS has at least four build steps that download things during the build (Flutter/pub, `sentry_flutter`, `super_native_extensions`, and the `jni` plugin's JDK need). It also ships prebuilt binaries (7-Zip, two JAR files), and it would need permission exceptions that Flathub reviews by hand.
- **Both formats need some app code changes, not just CI changes.** The self-updater, the release-asset picker, the 7-Zip `chmod`, and the deep-link `.desktop` writer all assume TriOS runs from a normal writable folder. They would break or misbehave inside an AppImage or Flatpak.
- **Recommendation:** ship an x86_64 AppImage first, next to the existing zip. Add a `.flatpak` bundle only if users ask for it. Leave Flathub for later, if ever.

## How TriOS builds for Linux today

From [`.github/workflows/main.yml`](../../.github/workflows/main.yml):

- Trigger: any pushed tag.
- The `build-linux` job runs on `ubuntu-22.04`. It installs `ninja-build cmake g++ libgtk-3-dev libcurl4-openssl-dev default-jdk`, sets up Flutter with `subosito/flutter-action`, deletes Windows/macOS assets, patches a compiler flag out of plugin `CMakeLists.txt` files, and runs `flutter build linux`.
- The output folder `build/linux/x64/release/bundle` gets zipped as `TriOS-Linux.zip`.
- `create-release` makes the GitHub release with `ncipollo/release-action` and uploads each zip with `shogo82148/actions-upload-release-asset`.
- There is no arm64 Linux build. There is no signing.

Because it builds on Ubuntu 22.04, the current zip already needs glibc 2.35 or newer on the user's machine ([Ubuntu jammy libc6 is 2.35](https://packages.ubuntu.com/jammy/libc6)).

### Linux native pieces that matter for packaging

From [`linux/flutter/generated_plugins.cmake`](../../linux/flutter/generated_plugins.cmake), the Linux build compiles these plugins: `desktop_drop`, `gtk`, `irondash_engine_context`, `screen_retriever_linux`, `sentry_flutter`, `super_native_extensions`, `url_launcher_linux`, `window_manager`, `window_size`, and the FFI plugin `jni`.

| Piece | What it does at build time | Why it matters |
|---|---|---|
| `sentry_flutter` 9.20.0 | Its CMake file uses `FetchContent` to `git clone` `getsentry/sentry-native` 0.13.8 during the build, with the crashpad backend. Found in the pub cache at `sentry_flutter-9.20.0/sentry-native/sentry-native.cmake` and `CMakeCache.txt`. | Needs network during the build. Blocks an offline (Flathub) build unless the source is supplied another way. |
| `super_native_extensions` 0.9.1 | Uses Cargokit. Cargokit either downloads a signed prebuilt Rust library or builds the Rust crate with `cargo` ([Cargokit precompiled binaries doc](https://github.com/irondash/cargokit/blob/main/docs/precompiled_binaries.md), same file ships in the package's `cargokit/docs/`). | Needs network or a Rust toolchain plus all crates. |
| `jni` 0.14.2 (pulled in by `sentry_flutter`) | Its `src/CMakeLists.txt` runs `find_package(JNI REQUIRED COMPONENTS JVM)` and links `libdartjni.so` against `libjvm`. `dartjni.c` calls `JNI_CreateJavaVM`. | This is why CI installs `default-jdk`. A Flatpak source build needs a JDK in the SDK. AppImage tools that walk library dependencies may complain that `libjvm.so` can't be found. |
| `flutter_inappwebview` | Not in the Linux plugin list. `catalog_page.dart` shows a "Linux not supported" state instead of a webview. | No WebKitGTK needed. Good news for both formats. |
| `file_picker` 10.3.10 | On Linux it talks to the XDG Desktop Portal `FileChooser` over D-Bus (`lib/src/linux/file_picker_linux.dart`). | Works inside Flatpak. But see the note on portal paths below. |
| 7-Zip | Prebuilt static `7zzs` binaries for x64 and arm64 in `assets/linux/7zip/`. At startup, [`seven_zip.dart`](../../lib/compression/seven_zip/seven_zip.dart) runs `chmod +x` on the file inside `data/flutter_assets`. | Inside an AppImage or Flatpak, the app's files are read-only. The `chmod` will fail, so the file must already be executable when packaged. |
| JARs | `assets/common/JpsAtHome.jar` and `assets/common/TriOS-Mod/jars/TriOS-Companion-Mod.jar` are prebuilt. | Flathub does not allow prebuilt files in a submission (see Flathub section). |

Note: the project `CLAUDE.md` mentions libarchive bindings in `lib/libarchive/`. That folder does not exist in the repo right now, so libarchive plays no part in this.

## Code in TriOS that would break inside a package

These are problems in both formats unless noted.

1. **Self-update picks the wrong file.** [`SelfUpdater.getAssetForPlatform`](../../lib/trios/self_updater/self_updater.dart) (line 376) picks the first release asset whose name contains `linux`. If a release has `TriOS-Linux.zip`, `TriOS-Linux-x86_64.AppImage`, and `TriOS-Linux-x86_64.AppImage.zsync`, which one is picked depends on upload order. New asset names must not contain `linux`, or the matcher must get stricter. This affects the *existing zip users* too, not just package users.
2. **Self-update writes into the app folder.** `replaceSelf` (line 153) overwrites files next to `Platform.resolvedExecutable`, then restarts with `nohup` (line 122).
   - In an AppImage, the executable lives inside a read-only mount. The AppImage runtime sets the `APPIMAGE` environment variable to the real `.AppImage` file path and `APPDIR` to the mount point ([`runtime.c`](https://github.com/AppImage/type2-runtime/blob/75849dce7cc37e4319b633df1f116ca895c71a12/src/runtime/runtime.c#L1833-L1835)). An AppImage-aware updater would download the new `.AppImage`, replace the file at `$APPIMAGE`, and relaunch it.
   - In a Flatpak, the app is mounted at `/app` and Flatpak points the app at writable folders under `~/.var/app/$APPID/` instead ([`flatpak run` man page](https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-run)). `/app` is on the list of reserved paths that can't be opened up ([Sandbox permissions, "Reserved Paths"](https://docs.flatpak.org/en/latest/sandbox-permissions.html)). Updates come from `flatpak update`. Flatpak does offer a portal that lets an app ask to install its own update (`CreateUpdateMonitor` and `Update` in [`org.freedesktop.portal.Flatpak.xml`](https://github.com/flatpak/flatpak/blob/main/data/org.freedesktop.portal.Flatpak.xml)), but that only helps when installed from a repository, not from a loose bundle file. Detect Flatpak with the `FLATPAK_ID` environment variable, which Flatpak always sets ([`flatpak run` man page](https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-run)).
   - The simplest fix for both: turn off the in-app updater when `APPIMAGE` or `FLATPAK_ID` is set, and show "update available, download it from GitHub" instead. AppImage can do better later.
3. **7-Zip `chmod` fails on read-only files.** Fix: in the packaging step, run `chmod +x` on `data/flutter_assets/assets/linux/7zip/*/7zzs` before building the package. Also delete the other CPU's `7zzs` to save space.
4. **Deep-link registration writes the wrong path.** [`protocol_registration.dart`](../../lib/trios/deep_link/protocol_registration.dart) (line 119) writes `~/.local/share/applications/trios-starsector-mod.desktop` with `Exec="${Platform.resolvedExecutable}"`.
   - In an AppImage that path is a temporary mount that changes every launch. It should use `$APPIMAGE`.
   - In a Flatpak, the sandbox can't see `~/.local/share/applications` unless home access is granted, and the `Exec` path would point inside the sandbox. The `starsector-mod` URL scheme should be declared with `MimeType=x-scheme-handler/starsector-mod;` in the packaged `.desktop` file instead.
5. **Settings folder moves (Flatpak only).** TriOS stores data in `getApplicationSupportDirectory()` ([`main.dart`](../../lib/main.dart) line 239). On Linux that is `$XDG_DATA_HOME/<application id>` ([`path_provider_linux` source](https://github.com/flutter/packages/blob/main/packages/path_provider/path_provider_linux/lib/src/path_provider_linux.dart)). Flatpak sets `XDG_DATA_HOME` to `~/.var/app/<app-id>/data` ([Flatpak conventions](https://docs.flatpak.org/en/latest/conventions.html)). So a user who switches from the zip to the Flatpak starts with empty settings unless TriOS copies them over.
6. **Process detection can't see the game (Flatpak only).** [`unix_process_detector.dart`](../../lib/trios/process_detection/unix_process_detector.dart) runs `ps aux`. A Flatpak app has "no access to processes outside the sandbox" ([Sandbox permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html)). A game started by TriOS inside the sandbox would be visible. A game started any other way would not.

## AppImage

### What an AppImage is made of

- An AppImage is a small program (the "runtime") glued to a compressed read-only filesystem. The runtime "mounts the payload via FUSE and executes the entrypoint" ([type2-runtime README](https://github.com/AppImage/type2-runtime)).
- Inside, the folder (called an AppDir) must have an `AppRun` executable, a `.desktop` file, and a `.DirIcon`, ideally a 256×256 PNG ([AppImage spec draft](https://github.com/AppImage/AppImageSpec/blob/master/draft.md)).

### Tools

| Tool | What it does | Notes |
|---|---|---|
| [appimagetool](https://github.com/AppImage/appimagetool) | Turns an existing AppDir into an AppImage. Does not collect libraries. | Downloads the latest static runtime from type2-runtime releases, or takes a local one with `--runtime-file`. Has `-u` for update info, `-s`/`--sign-key` for GPG signing. Binaries: `appimagetool-x86_64.AppImage`, `appimagetool-aarch64.AppImage` ([continuous release](https://github.com/AppImage/appimagetool/releases/tag/continuous)). |
| [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) | Builds the AppDir: copies in the shared libraries your binary needs, then calls appimagetool through its [AppImage plugin](https://github.com/linuxdeploy/linuxdeploy-plugin-appimage). | x86_64 and aarch64 builds on its [continuous release](https://github.com/linuxdeploy/linuxdeploy/releases/tag/continuous). The plugin reads `LDAI_OUTPUT`, `LDAI_UPDATE_INFORMATION`, `LDAI_SIGN`, `LDAI_SIGN_KEY`, `LDAI_RUNTIME_FILE`. |
| [linuxdeploy-plugin-gtk](https://github.com/linuxdeploy/linuxdeploy-plugin-gtk) | Also bundles GTK, GLib schemas, gdk-pixbuf loaders, and the Adwaita theme. | Its launch hook exports `GDK_BACKEND=x11`, `GTK_THEME=Adwaita:...`, `XDG_DATA_DIRS`, `GTK_PATH`, and more ([script source](https://github.com/linuxdeploy/linuxdeploy-plugin-gtk/blob/master/linuxdeploy-plugin-gtk.sh), lines 240–321). Child processes, including the game, inherit these. |
| [appimage-builder](https://github.com/AppImageCrafters/appimage-builder) | Recipe-driven. Pulls libraries from apt packages. | Used by LocalSend and RustDesk (RustDesk uses its own fork). |

### Two ways to package TriOS

**Option A — thin AppImage (recommended first).** Put the Flutter bundle in an AppDir as-is, add `AppRun`, `.desktop`, and icon, and run appimagetool. Don't bundle GTK. The user's system provides GTK 3, exactly like the zip today. The AppImage then has the same requirements as the zip (glibc 2.35+, GTK 3 installed), but it's one file and can carry update info. Least risk, least work.

**Option B — full AppImage with linuxdeploy + GTK plugin.** Bundles GTK and friends, so it can run on systems without GTK 3. But it forces X11 (`GDK_BACKEND=x11`) and the Adwaita theme, and passes those variables down to the game. It may also stop on `libdartjni.so`'s link to `libjvm.so`, which isn't on the build machine's library path. Saber works around library lookup by adding the bundle's `lib` folder to `LD_LIBRARY_PATH` before running linuxdeploy ([Saber `linux.yml`](https://github.com/saber-notes/saber/blob/07774e4051bc8af9fd47c2c6bcf17f3ea80c8a13/.github/workflows/linux.yml#L114-L138)). Worth trying only if users on unusual distros report missing GTK.

### glibc: which distro to build on

- AppImage's guidance: build on "the oldest still-supported LTS version of Ubuntu" you want to support ([AppImage best practices](https://docs.appimage.org/reference/best-practices.html)).
- Flutter supports deploying to Ubuntu 20.04–24.04 and Debian 10–13, on x64 and Arm64 ([Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms)).
- TriOS already builds on `ubuntu-22.04`, giving a glibc 2.35 floor. Keeping that is fine for a first version.
- GitHub keeps at most two GA Ubuntu images. The oldest label starts deprecation when a new one goes GA ([runner-images README](https://github.com/actions/runner-images)). Ubuntu 26.04 is currently in preview, so `ubuntu-22.04` will likely go away. When it does, build inside an `ubuntu:22.04` container on a newer runner to keep the same floor.

### FUSE on users' machines

- Older AppImages need `libfuse2`, which Ubuntu 22.04+ no longer installs by default (on 24.04 the package is `libfuse2t64`) ([AppImage FUSE troubleshooting](https://docs.appimage.org/user-guide/troubleshooting/fuse.html)).
- The new static runtime removes that: "libfuse2 is no longer required on the target system" ([type2-runtime README](https://github.com/AppImage/type2-runtime)). Current appimagetool embeds this runtime by default.
- It still needs a setuid-root `fusermount` or `fusermount3` program on `PATH`. Without one it prints "No suitable fusermount binary found on the $PATH" ([`runtime.c`, `find_fusermount`](https://github.com/AppImage/type2-runtime/blob/75849dce7cc37e4319b633df1f116ca895c71a12/src/runtime/runtime.c#L417-L503)). Mainstream desktop distros ship one.
- Fallback for users with no FUSE: `./TriOS.AppImage --appimage-extract-and-run`, or `APPIMAGE_EXTRACT_AND_RUN=1` ([FUSE troubleshooting](https://docs.appimage.org/user-guide/troubleshooting/fuse.html); also handled in `runtime.c` line 1580).

### FUSE on the CI runner

linuxdeploy and appimagetool are themselves AppImages. On a GitHub runner, either install FUSE (Saber runs `sudo apt-get install libfuse2t64`, [Saber `linux.yml`](https://github.com/saber-notes/saber/blob/07774e4051bc8af9fd47c2c6bcf17f3ea80c8a13/.github/workflows/linux.yml#L109-L112)) or set `APPIMAGE_EXTRACT_AND_RUN=1`. Docker containers don't allow FUSE, so inside a container the environment variable is the only option ([FUSE troubleshooting, Docker note](https://docs.appimage.org/user-guide/troubleshooting/fuse.html)).

### Updates

- Update info is text embedded in the AppImage. For GitHub releases the format is `gh-releases-zsync|<user>|<repo>|<tag>|<filename pattern>`. Tag can be `latest` (stable only), `latest-pre`, or `latest-all`. Pre-releases are ignored with `latest` ([AppImage spec, update information](https://github.com/AppImage/AppImageSpec/blob/master/draft.md)).
- For TriOS that would be `gh-releases-zsync|wispborne|trios|latest|TriOS-*-x86_64.AppImage.zsync`. TriOS marks tags containing `dev`, `rc`, etc. as pre-releases, so `latest` would skip those.
- Passing that string with `-u` (appimagetool) or `LDAI_UPDATE_INFORMATION` (linuxdeploy) also generates the `.zsync` file, if `zsyncmake` is installed ([appimagetool README](https://github.com/AppImage/appimagetool); [linuxdeploy-plugin-appimage README](https://github.com/linuxdeploy/linuxdeploy-plugin-appimage)). Upload both files to the release.
- Tools like AppImageUpdate can then update the file. An app can also run `AppImageUpdate $APPIMAGE` itself. The AppImage docs say not to update without asking the user ([AppImage updates guide](https://docs.appimage.org/packaging-guide/optional/updates.html)).
- For TriOS, the realistic first step is to keep the in-app updater but teach it to replace `$APPIMAGE` (see item 2 above). zsync info is a cheap extra.

### arm64

- GitHub has free `ubuntu-24.04-arm` and `ubuntu-22.04-arm` runners for public repos ([GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)).
- **Catch:** Flutter only publishes prebuilt Linux SDK downloads for x64. Every Linux entry in [`releases_linux.json`](https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json) has `dart_sdk_arch: x64`, including 3.47.1. `subosito/flutter-action` looks the version up in that file ([setup.sh](https://github.com/subosito/flutter-action/blob/main/setup.sh)), so on an arm runner it won't find 3.47.1. Saber gets around this by keeping Flutter as a git submodule ([Saber `linux.yml`](https://github.com/saber-notes/saber/blob/07774e4051bc8af9fd47c2c6bcf17f3ea80c8a13/.github/workflows/linux.yml#L61-L64)). TriOS would need to `git clone --branch 3.47.1 https://github.com/flutter/flutter` on arm.
- TriOS already ships an arm64 `7zzs`, so that part is ready.

### Files to add to the repo (AppImage)

- `linux/packaging/org.wisp.trios.desktop` — `Name=TriOS`, `Exec=TriOS %u`, `Icon=org.wisp.trios`, `Categories=Game;Utility;`, `MimeType=x-scheme-handler/starsector-mod;`.
- An icon of at least 256×256. The Linux window icon (`assets/images/telos_faction_crest.png`) is only 128×128. `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png` and `app_icon_512.png` already exist.
- Optional: `linux/packaging/org.wisp.trios.metainfo.xml` (AppStream). linuxdeploy checks it if present. Required for Flatpak anyway.
- An `AppRun`. The simplest is a symlink to the `TriOS` binary. The Flutter binary finds its `lib/` and `data/` relative to itself (`CMAKE_INSTALL_RPATH "$ORIGIN/lib"` in [`linux/CMakeLists.txt`](../../linux/CMakeLists.txt)).

### Workflow sketch (untested)

Added after the existing zip step in `build-linux`:

```yaml
      - name: Build AppImage
        env:
          APPIMAGE_EXTRACT_AND_RUN: 1
        run: |
          B=build/linux/x64/release/bundle
          chmod +x $B/data/flutter_assets/assets/linux/7zip/x64/7zzs
          rm -rf $B/data/flutter_assets/assets/linux/7zip/arm64
          mkdir -p AppDir
          cp -r $B/* AppDir/
          ln -s TriOS AppDir/AppRun
          cp linux/packaging/org.wisp.trios.desktop AppDir/
          cp macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png AppDir/org.wisp.trios.png
          ln -s org.wisp.trios.png AppDir/.DirIcon
          sudo apt-get install -y zsync
          wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
          chmod +x appimagetool-x86_64.AppImage
          ARCH=x86_64 ./appimagetool-x86_64.AppImage \
            -u "gh-releases-zsync|wispborne|trios|latest|TriOS-*-x86_64.AppImage.zsync" \
            AppDir "TriOS-${GITHUB_REF_NAME}-x86_64.AppImage"
```

Then upload `TriOS-*-x86_64.AppImage` and its `.zsync` as artifacts, and add two more upload steps in `create-release`. Pin the appimagetool download to a checksum or a copy you control before relying on it, since `continuous` changes.

## Flatpak

### Toolchain

- `flatpak-builder` reads a manifest (YAML or JSON), builds each module inside the SDK, and writes an OSTree repo. `flatpak build-bundle` turns that repo into a single `.flatpak` file ([single-file bundles](https://docs.flatpak.org/en/latest/single-file-bundles.html)).
- Runtimes: `org.freedesktop.Platform` (new major version every August, supported for two years) or `org.gnome.Platform`, which is built on top of it ([Flathub runtimes doc](https://docs.flathub.org/docs/for-app-authors/runtimes)). Freedesktop SDK 26.08.0 was released 2026-09-01 ([freedesktop-sdk releases](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/releases)).
- The Freedesktop runtime already includes `gtk3`, `curl`, `procps` (so `ps` exists), and `flatpak-xdg-utils` (so `xdg-open` forwards to the portal) ([`elements/platform.bst`](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/blob/master/elements/platform.bst)). So TriOS does not need the bigger GNOME runtime. RustDesk and LocalSend both ship Flutter apps on the Freedesktop runtime.

### Running it in GitHub Actions

- Official action: [`flatpak/flatpak-github-actions/flatpak-builder@v6`](https://github.com/flatpak/flatpak-github-actions). It runs inside `ghcr.io/flathub-infra/flatpak-github-actions:<runtime tag>` with `options: --privileged`. Inputs include `manifest-path`, `bundle`, `arch`, `cache`, `cache-key`, `repository-url` (where users get the runtime), and `upload-artifact`.
- The README's tag table lists up to `freedesktop-24.08` and `gnome-48`. Check the [flathub-infra package list](https://github.com/orgs/flathub-infra/packages) for newer tags before picking one.
- arm64: the README's multi-arch example uses a matrix of `ubuntu-24.04` / `x86_64` and `ubuntu-24.04-arm` / `aarch64`. QEMU emulation also works but is slow.
- RustDesk skips the action. It installs `flatpak flatpak-builder` with apt in an Ubuntu 22.04 container and runs `flatpak-builder` and `flatpak build-bundle` by hand ([RustDesk `flutter-build.yml`](https://github.com/rustdesk/rustdesk/blob/bf1ebe5be2f5ac1ce634572e9ff7bc88e8b1d6aa/.github/workflows/flutter-build.yml#L2415-L2498)).

### The offline-build problem, and two ways around it

Flathub builds have no network access. All sources must be listed in the manifest ahead of time ([Flathub requirements, "No network access during build"](https://docs.flathub.org/docs/for-app-authors/requirements#no-network-access-during-build)). Flutter normally downloads its Dart SDK, engine files, and pub packages during the build. That fails in a sandboxed build ([flatpak-flutter README](https://github.com/TheAppgineer/flatpak-flutter)).

**Way 1 — reuse the prebuilt bundle (for a self-hosted `.flatpak` file).**
The manifest takes the already-built `TriOS-Linux.zip` (or the bundle folder) as a local `file` source and just copies it into `/app`. No Flutter in the Flatpak build at all. Offline rules don't matter when you build it yourself in CI.
- RustDesk does this with its `.deb` ([`flatpak/rustdesk.json`](https://github.com/rustdesk/rustdesk/blob/bf1ebe5be2f5ac1ce634572e9ff7bc88e8b1d6aa/flatpak/rustdesk.json)).
- LocalSend's Flathub manifest does it too, downloading its own GitHub release tarballs per CPU ([`org.localsend.localsend_app.yml`](https://github.com/flathub/org.localsend.localsend_app/blob/baaea3098bfef8324d41bbc98c80563d0f37c734/org.localsend.localsend_app.yml)). New Flathub submissions can no longer do this (see next section).
- Estimated effort: small for the build itself.

**Way 2 — build from source with flatpak-flutter (needed for Flathub).**
- [flatpak-flutter](https://github.com/TheAppgineer/flatpak-flutter) (v0.15.0, June 2026) reads a `flatpak-flutter.yml` and writes a manifest where Flutter SDK, pub packages, and Rust crates are all listed as pinned sources. Flutter's own docs point to it for Flatpak ([Flutter Linux deployment](https://docs.flutter.dev/deployment/linux)).
- It already knows how to handle `super_native_extensions` ([`foreign_deps.json`](https://github.com/TheAppgineer/flatpak-flutter/blob/master/foreign_deps/foreign_deps.json)).
- It does **not** list `sentry_flutter`. Its README says that when a native build still downloads something, you add that download to the manifest yourself ([README, "Deal with Foreign Dependencies"](https://github.com/TheAppgineer/flatpak-flutter#deal-with-foreign-dependencies)). For TriOS, that means adding `sentry-native` 0.13.8 (with its git submodules, such as crashpad) as a source and pointing CMake's `FetchContent` at it.
- The `jni` plugin needs a JDK in the build. That means adding the OpenJDK SDK extension.
- Saber is a working example: [`flatpak-flutter.yaml`](https://github.com/flathub/com.adilhanney.saber/blob/869cb3e08a146e09065c7eae14956ecaca1eaea9/flatpak-flutter.yaml) on the GNOME runtime with an LLVM SDK extension, Flutter from a submodule, and `flutter build linux --no-pub`.
- The generated sources must be regenerated whenever `pubspec.lock` or the Flutter version changes.
- Estimated effort: large, with unknowns.

### Flathub publication vs. a `.flatpak` file on GitHub

**A `.flatpak` file on the release page:**
- Users install with `flatpak install TriOS.flatpak`. The bundle does not contain the runtime ([single-file bundles](https://docs.flatpak.org/en/latest/single-file-bundles.html)). Pass `--runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo` so Flatpak knows where to get it. The action's `repository-url` input does this.
- A bundle gets no automatic updates unless you also host a Flatpak repository and pass `--repo-url` ([`flatpak build-bundle` man page](https://github.com/flatpak/flatpak/blob/main/doc/flatpak-build-bundle.xml)). Hosting one means running something like flat-manager, which the action supports (`flat-manager@v6`), but that's a server to run.
- No review. You choose the permissions.

**Flathub:**
- Must build "entirely from source", including runtime dependencies in the manifest. "Binary or precompiled files must not be present in the submission pull request." Exceptions go mainly to well-known vendors ([Flathub requirements](https://docs.flathub.org/docs/for-app-authors/requirements#building-from-source)). For TriOS that means building `7zzs` from 7-Zip source, and building `JpsAtHome.jar` and `TriOS-Companion-Mod.jar` from source in the manifest.
- App ID: apps hosted on GitHub must use `io.github.` and have at least 4 parts ([requirements, Application ID](https://docs.flathub.org/docs/for-app-authors/requirements#application-id)). TriOS currently uses `org.wisp.trios` (`APPLICATION_ID` in `linux/CMakeLists.txt`). Unless the author controls `wisp.org`, that would become something like `io.github.wispborne.TriOS`. Flatpak expects the ID to be reused in many places ([Flatpak conventions](https://docs.flatpak.org/en/latest/conventions.html)): the `.desktop` file name, icon name, and metainfo name. The GTK application ID should match too.
- Permissions: "Static permissions must be kept to an absolute minimum." Where a portal covers the need, using it is mandatory ([requirements, Permissions](https://docs.flathub.org/docs/for-app-authors/requirements#permissions)). The linter flags `--filesystem=host`, `--filesystem=home`, and `--talk-name=org.freedesktop.Flatpak`. Each needs a written exception, granted "on sufficient explanation" ([Flathub linter](https://docs.flathub.org/docs/for-app-authors/linter)).
- "Applications that rely on host components or complicated post installation setups for core functionality will not be accepted", with case-by-case exceptions ([requirements, "Host-dependent applications"](https://docs.flathub.org/docs/for-app-authors/requirements)). TriOS needs a separately installed game. That's probably fine (other game launchers are on Flathub), but a reviewer decides.
- Must have a valid metainfo file, a `.desktop` file, and an SVG or at least 256×256 PNG icon. The license must be correct in the metainfo ([requirements](https://docs.flathub.org/docs/for-app-authors/requirements)). TriOS uses a custom "TriOS Community License v1.0" ([`LICENSE.txt`](../../LICENSE.txt)), which has no SPDX ID, so it would need a `LicenseRef-...` value.
- The Flathub linter treats metainfo warnings as errors, and screenshots get mirrored to Flathub's servers ([Flathub linter](https://docs.flathub.org/docs/for-app-authors/linter)).
- Flathub builds both x86_64 and aarch64 on its own servers once the build is from source ([flatpak-flutter README](https://github.com/TheAppgineer/flatpak-flutter)). So arm64 would come free there.

### Sandbox permissions TriOS would need

| Need | Option | Trade-off |
|---|---|---|
| Network (mod downloads, version checks, Sentry) | `--share=network` | Standard. Sandboxes have no network by default ([Sandbox permissions](https://docs.flatpak.org/en/latest/sandbox-permissions.html)). |
| Window and GPU | `--socket=wayland`, `--socket=fallback-x11`, `--share=ipc`, `--device=dri` | Standard for GUI apps. The game needs `--socket=x11` (LWJGL 2 is X11-only) and `--socket=pulseaudio` for sound if it runs inside the sandbox. |
| Game folder anywhere on disk | `--filesystem=home` or `--filesystem=host` | `host` exposes all top-level paths except reserved ones (`/app`, `/usr`, `/etc`, and others) ([Sandbox permissions, "Reserved Paths"](https://docs.flatpak.org/en/latest/sandbox-permissions.html)). A game in `/usr/...` can't be reached at all. Flathub needs an exception for either. |
| Game folder via the file chooser only | No static permission; `file_picker` already uses the portal | Files the app has no permission for show up under a document-portal path such as `/run/flatpak/doc/...`, not the real path ([Document portal docs](https://flatpak.github.io/xdg-desktop-portal/docs/documents-and-fuse.html)). TriOS stores and shows the game path, runs scripts in it, and reads `vmparams`. A fake-looking path would confuse users and might not work for launching. Not a realistic fit. |
| Launch the game outside the sandbox | `--talk-name=org.freedesktop.Flatpak`, then `flatpak-spawn --host ./starsector.sh` | `--host` "run[s] the command unsandboxed on the host" ([`flatpak-spawn` man page](https://github.com/flatpak/flatpak/blob/main/doc/flatpak-spawn.xml)). This is a full sandbox escape. Flathub needs an exception. TriOS code would have to add `flatpak-spawn --host` in front of the launch and `ps` commands. |
| Open folders and links | Nothing extra | `xdg-open` in the runtime forwards to the portal. |

For a self-hosted bundle, a practical set is: network, display sockets, `--device=dri`, `--socket=pulseaudio`, `--filesystem=host`, and possibly `--talk-name=org.freedesktop.Flatpak`. At that point the sandbox is protecting very little. That's the main argument that Flatpak adds little value for TriOS compared to AppImage.

### Game launch inside the Flatpak sandbox

This needs a real test before committing to Flatpak.

- On Linux, TriOS starts the game by running the game's own launcher script from the game folder ([`launcher.dart`](../../lib/launcher/launcher.dart) line 686). A child process of a Flatpak app runs inside the same sandbox, using the runtime's libraries instead of the host's.
- Starsector uses LWJGL 2. LWJGL 2's `XRandR` class runs the `xrandr` command-line program to read and set display modes ([LWJGL 2 `XRandR.java`](https://github.com/LWJGL/lwjgl/blob/master/src/java/org/lwjgl/opengl/XRandR.java), lines 72 and 184–210).
- The Freedesktop runtime includes the `libXrandr` library but not the `xrandr` program. It has `xorg-lib-xrandr`, but no `xorg-app-xrandr` ([`platform.bst`](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/blob/master/elements/platform.bst)).
- So inside the sandbox, the game may fail to set its display mode. Fixes would be to bundle `xrandr` into the Flatpak, or to launch the game with `flatpak-spawn --host`.
- AppImage does not have this problem, because an AppImage is not sandboxed. The only side effect is the environment variables mentioned under linuxdeploy-plugin-gtk, if Option B is used.

### Files to add to the repo (Flatpak)

- `linux/packaging/<app-id>.yml` — the manifest.
  - Freedesktop runtime.
  - `command: TriOS`.
  - The finish-args chosen above.
  - One module that unpacks the prebuilt bundle into `/app/trios`, symlinks `/app/bin/TriOS`, runs `chmod +x` on `7zzs`, and installs the metadata files. The `.desktop` file must be named `<app-id>.desktop` and go in `/app/share/applications/`. Icons must be named `<app-id>.png` or `.svg` in `/app/share/icons/hicolor/<size>/apps/`, at most 512×512. Metainfo goes in `/app/share/metainfo/<app-id>.metainfo.xml` ([Flatpak conventions](https://docs.flatpak.org/en/latest/conventions.html)).
- `linux/packaging/<app-id>.desktop` — the same file the AppImage uses. Include the `starsector-mod` scheme in `MimeType`.
- `linux/packaging/<app-id>.metainfo.xml` — AppStream. Needs ID, name, summary, description, license, releases, screenshots (screenshots are required for Flathub).
- Icons: reuse the macOS `app_icon_256.png` / `app_icon_512.png`.
- For Flathub only: the `flatpak-flutter.yml` input, the generated `pubspec-sources.json` and `cargo-sources.json`, the `sentry-native` source module, a 7-Zip source module, JAR build modules, and a `LICENSE` install step to `$FLATPAK_DEST/share/licenses/$FLATPAK_ID`.

### Workflow sketch for a self-hosted bundle (untested)

```yaml
  build-flatpak:
    needs: build-linux
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/flathub-infra/flatpak-github-actions:freedesktop-24.08   # check for a newer tag
      options: --privileged
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: built-linux, path: linux/packaging }
      - uses: flatpak/flatpak-github-actions/flatpak-builder@v6
        with:
          manifest-path: linux/packaging/org.wisp.trios.yml
          bundle: TriOS-x86_64.flatpak
          repository-url: https://dl.flathub.org/repo/flathub.flatpakrepo
```

## Signing, attestations, and release upload

- **AppImage:** GPG-sign with appimagetool `--sign --sign-key <id>` (or `LDAI_SIGN=1` and `LDAI_SIGN_KEY` in linuxdeploy). In CI, pass the key's passphrase with `APPIMAGETOOL_SIGN_PASSPHRASE` ([appimagetool README](https://github.com/AppImage/appimagetool)). The signature sits inside the file. Few users check it.
- **Flatpak bundle:** `flatpak build-bundle` takes `--gpg-keys=FILE` to include a public key ([build-bundle man page](https://github.com/flatpak/flatpak/blob/main/doc/flatpak-build-bundle.xml)). The action has a `gpg-sign` input. Signing matters mostly when you host a repository. On Flathub, Flathub signs.
- **Simpler and more useful for GitHub downloads:** GitHub artifact attestations. Add `actions/attest@v4` with `subject-path` pointing at each file, plus the `id-token: write` and `attestations: write` permissions. Users verify with `gh attestation verify` ([GitHub docs, artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations)). This covers the zips too.
- **Upload:** copy the existing pattern in `create-release`, adding one `shogo82148/actions-upload-release-asset` step per new file (AppImage, `.zsync`, `.flatpak`). Or switch to one step that uploads a glob. Keep new asset names free of the word `linux` until `getAssetForPlatform` is fixed (see item 1 above).

## Real-world precedent

| App | AppImage in GitHub Actions | Flatpak |
|---|---|---|
| **Saber** (Flutter note app) | linuxdeploy on `ubuntu-latest` and `ubuntu-24.04-arm`. Sets `LDAI_UPDATE_INFORMATION` to a `gh-releases-zsync` string. Uploads to the release with `svenstaro/upload-release-action` ([`linux.yml`](https://github.com/saber-notes/saber/blob/07774e4051bc8af9fd47c2c6bcf17f3ea80c8a13/.github/workflows/linux.yml)). | On Flathub, built from source with flatpak-flutter ([`com.adilhanney.saber` repo](https://github.com/flathub/com.adilhanney.saber/blob/869cb3e08a146e09065c7eae14956ecaca1eaea9/flatpak-flutter.yaml)). |
| **RustDesk** (Flutter + Rust remote desktop) | appimage-builder (its own fork) on `ubuntu-22.04`, repacking its `.deb` ([`flutter-build.yml` L2364–2413](https://github.com/rustdesk/rustdesk/blob/bf1ebe5be2f5ac1ce634572e9ff7bc88e8b1d6aa/.github/workflows/flutter-build.yml#L2364-L2413)). | `.flatpak` bundle built in CI from the prebuilt `.deb` on the Freedesktop runtime, for x86_64 and aarch64, attached to GitHub releases ([L2415–2498](https://github.com/rustdesk/rustdesk/blob/bf1ebe5be2f5ac1ce634572e9ff7bc88e8b1d6aa/.github/workflows/flutter-build.yml#L2415-L2498); [manifest](https://github.com/rustdesk/rustdesk/blob/bf1ebe5be2f5ac1ce634572e9ff7bc88e8b1d6aa/flatpak/rustdesk.json)). Uses `--filesystem=home` and `--talk-name=org.freedesktop.Flatpak`. This is the closest model for a TriOS self-hosted bundle. |
| **LocalSend** (Flutter file sharing) | appimage-builder via `AppImageCrafters/build-appimage` on `ubuntu-22.04`, with separate x64 and arm64 workflows ([`build_linux_appimage_x64.yml`](https://github.com/localsend/localsend/blob/25b3019c6ff77af17a6436220d2af6dec311387a/.github/workflows/build_linux_appimage_x64.yml)). | On Flathub, repackaging its own GitHub release tarballs on the Freedesktop runtime ([manifest](https://github.com/flathub/org.localsend.localsend_app/blob/baaea3098bfef8324d41bbc98c80563d0f37c734/org.localsend.localsend_app.yml)). This is an older listing. New submissions must build from source. |

## Recommendation and effort

Rough estimates for one developer who knows the codebase. The "testing" in each row means trying it on at least Ubuntu, Fedora, and one Arch-based distro, including launching the game.

| Step | Work | Estimate |
|---|---|---|
| 1. App fixes needed by any package | Stricter release-asset matching. Detect `APPIMAGE` / `FLATPAK_ID` and change or disable self-update. Use `$APPIMAGE` in the deep-link `.desktop` entry. Add a `.desktop` file and 256px icon. | 1–2 days |
| 2. x86_64 AppImage (thin, Option A) | New steps in `build-linux`, a release upload, optional zsync update info, testing. | 1–2 days |
| 3. arm64 Linux zip + AppImage | New matrix entry on `ubuntu-22.04-arm`, Flutter from git, testing on arm hardware. | 1–2 days |
| 4. Self-hosted `.flatpak` bundle | Manifest reusing the zip, metainfo, permission choices, settings migration, `ps` and game launch through `flatpak-spawn --host` or bundled `xrandr`, testing. | 3–5 days |
| 5. Flathub | flatpak-flutter setup, sentry-native offline source, JDK extension, 7-Zip and JARs from source, app ID change, license metadata, screenshots, permission exception requests, review back-and-forth, then regenerating sources on every dependency bump. | 2–4 weeks at first, plus ongoing upkeep. Uncertain. |

**Suggested order:** 1 → 2. Ship it and see if Linux users use it. Do 3 if arm64 users ask. Consider 4 only if people specifically want Flatpak. Do 5 only if Flathub visibility is worth the ongoing cost.

## Open risks

- **Game launch from a Flatpak** may fail because `xrandr` is missing in the runtime. Needs a real test with the Linux version of Starsector.
- **Release asset matching** (`getAssetForPlatform`) can make existing zip installs download an AppImage or `.zsync` file as their "update". Fix before publishing any new Linux asset.
- **`libdartjni.so` links to `libjvm.so`.** It's harmless today because nothing loads it on Linux. It could make linuxdeploy (Option B) stop with a missing-dependency error. Option A avoids this.
- **`ubuntu-22.04` runner retirement** once Ubuntu 26.04 goes GA. Plan to move the build into an `ubuntu:22.04` container.
- **Flutter 3.47.1 support in flatpak-flutter.** The tool generates an SDK module per Flutter tag and may lag behind new Flutter releases. Only matters for Flathub.
- **Bundled libcurl/OpenSSL (Option B only).** Libraries copied from Ubuntu keep Ubuntu's built-in certificate path. That may break Sentry uploads on distros that keep certificates elsewhere, such as Fedora. Not confirmed; test if Option B is used.
- **Settings don't carry over** between the zip/AppImage (`~/.local/share/org.wisp.trios`) and a Flatpak (`~/.var/app/<id>/data/...`).
- **Environment variables leak** from the AppImage launcher into the game when using linuxdeploy-plugin-gtk (`GDK_BACKEND=x11`, `GTK_THEME`, `XDG_DATA_DIRS`). Probably harmless for Java, but untested.
