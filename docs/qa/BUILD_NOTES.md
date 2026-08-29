# Release APK build notes

Built **2026-08-20 17:14** (local). Includes dryer inspect diagrams (labeled typical-location box on lint / hood / hose).

## Artifact

| | |
|---|---|
| Path | `build/app/outputs/flutter-apk/app-release.apk` |
| Size | 99.0 MB (103,782,816 bytes) |
| Version | **0.1.0+1** |
| Command | `flutter build apk --release` |

ProGuard still has ML Kit optional-language `-dontwarn` rules in `android/app/proguard-rules.pro` (chinese, devanagari, japanese, korean, including `*TextRecognizerOptions` / `$Builder`). They are present in the release R8 configuration. Assemble completed without new missing-class rules.

## Retest before testers

Phone or emulator (`docs/qa/REGRESSION_PHONE.md`):

- Tools persist (`I have this` / `I don't`; required pan or screwdriver still gates invasive steps)
- Parts & cost: estimates only; no lint-filter / vent-kit / drain-trap purchase on a cleaning path
- Dryer inspect: lint-filter schematic + **Lint filter** box, LOOK FOR, chips; hood and hose if in path
- One dryer path: inspect (if not already answered) → I’ll repair → tools → guidance → Continue repair → Fixed → Repair history
- One washer path: same chain (won’t drain / drain filter); no dryer lint diagram
