![TriOS logo](assets/images/telos_faction_crest.png)
# TriOS
All-in-one Starsector launcher, mod manager, and toolkit.

## Tools

- **Launcher/Dashboard**: Replacement for the game launcher.
- **Mod Manager**: Manage your installed mods.
- **Mod Profiles**: Save custom mod loadouts. Load save game mod loadouts.
- **VRAM Estimator**: Now with visualization.
- **StarModder**: Online mod catalog & downloader.
- **Chipper**: Logfile viewer.
- **Rules.csv Autoreloader**: Hot reload for your mod rules.csv.

## Screenshots

### Dashboard/Launcher
![Dashboard](readme_resources/dashboard.png)
### Chipper
![Chipper](readme_resources/chipper.png)
### JRE Manager
![JRE Manager](readme_resources/jre.png)
### rules.csv Autoreloader
![rules.csv Autoreloader](readme_resources/rules_reload.png)

## Building TriOS

1. [Download and install/extract Flutter SDK](https://docs.flutter.dev/install/archive#stable-channel) so that it's on your path.
2. Follow the instructions for your platform so that InAppWebView can build: https://inappwebview.dev/docs/intro/#setup-windows.
3. Linux: Install `libcurl4-openssl-dev`.
4. Download the TriOS source code, navigate to it, and run
    ```
    flutter build windows
    ```
    (substitute `macos` or `linux` depending on your platform).
   1. On Linux, you may need to install missing libs, such as `libcurl4-openssl-dev` (for building Sentry). 
   2. Also, don't use the Snap version of Flutter, install it manually so it uses system libs.
5. The output should tell you where it placed the compiled program.


## Modifying TriOS
Whenever you change a model class (anything using code gen), you'll need to run the following command in a terminal in the project's root folder (I run it in IntelliJ's terminal). No need to do this unless you're changing TriOS code; the generated code is included in the source code.
```
dart run build_runner watch --delete-conflicting-outputs
```