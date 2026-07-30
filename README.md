# ComboFox

A mobile and web app for arcade fighting-game fans to browse game catalogs and view move lists — starting with Neo Geo and CPS2 classics.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) (`dart pub global activate flutterfire_cli`)
- [Node.js 20](https://nodejs.org/) (for Cloud Functions)

## Setup

```bash
# Install Flutter dependencies
flutter pub get

# Generate Firebase config (creates lib/firebase_options.dart)
# Use firebase_options_sample.dart as a reference for the expected shape.
flutterfire configure

# Install Cloud Functions dependencies
cd functions && npm install && cd ..
```

## Run

```bash
# Web
flutter run -d chrome

# iOS / Android (with a connected device or emulator)
flutter run
```

## Build & Deploy

```bash
# Build the web app
flutter build web --release

# Deploy everything (hosting + Firestore rules + Storage rules + Functions)
firebase deploy

# Or deploy selectively
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore
firebase deploy --only storage
```

## Android Release Signing (AAB)

This project is configured to sign release bundles from `android/key.properties`.

1. Generate an upload keystore (run once):

```bash
keytool -genkeypair -v \
	-keystore android/upload-keystore.jks \
	-keyalg RSA -keysize 2048 -validity 10000 \
	-alias upload
```

2. Create your local signing config file from the template:

```bash
cp android/key.properties.example android/key.properties
```

3. Edit `android/key.properties` with your real passwords and alias.

4. Build a release-signed Android App Bundle:

```bash
flutter build appbundle --release
```

If Google Play App Signing is enabled, this keystore is your upload key.

## Automatic Play Store internal releases

A push to `main` whose **commit subject** matches `vX.Y.Z description` builds a
signed Android App Bundle and publishes it to the Play Store's **Internal
testing** track. For example:

```bash
git commit -m "v1.2.3 Fix offline collection sync"
git push origin main
```

Other commits still run the workflow's quick validation job, but do not build
or publish anything. The release version name is taken from `vX.Y.Z`; its
version code is generated from the GitHub Actions run number and is therefore
monotonically increasing.

Before the first release, add these repository secrets under **Settings →
Secrets and variables → Actions**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 of the Play upload keystore: `base64 < android/upload-keystore.jks | tr -d '\n'` |
| `ANDROID_KEY_PROPERTIES` | Content of `android/key.properties` (with `storeFile=../upload-keystore.jks`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON key for a Google service account that has been granted access to this Play Console app |
| `FIREBASE_GOOGLE_SERVICES_JSON` | Content of the generated `android/app/google-services.json` |
| `FIREBASE_OPTIONS_DART` | Content of the generated `lib/firebase_options.dart` |

Create the app once in Play Console with package name
`net.combofox.androidapp`, then invite the service-account email in **Users and
permissions** with permission to publish to the internal track. The first
manual upload may be required by Play Console before API uploads are accepted.

## Project Structure

```
combofox/
├── lib/                     # Dart source (screens, models, services, widgets, theme)
├── android/                 # Android shell
├── ios/                     # iOS shell
├── web/                     # Web shell
├── test/                    # Flutter tests
├── assets/                  # Images, fonts
│   ├── fonts/
│   └── images/
├── functions/               # Firebase Cloud Functions (TypeScript, Node 20)
│   ├── src/index.ts
│   ├── package.json
│   └── tsconfig.json
├── pubspec.yaml             # Flutter dependencies
├── analysis_options.yaml    # Dart linter rules
├── firebase.json            # Firebase project config (hosting, firestore, storage, functions)
├── .firebaserc              # Firebase project alias
├── firestore.rules          # Firestore security rules
├── storage.rules            # Storage security rules
├── old/                     # Archived: original Python PDF generator (historical)
├── LICENSE
└── README.md
```

## Firebase Config

| File | Purpose | Git-tracked? |
|---|---|---|
| `firebase.json` | Project-wide Firebase config | Yes |
| `.firebaserc` | Project alias (`otaku-playbook`) | Yes |
| `firestore.rules` | Firestore security rules | Yes |
| `storage.rules` | Storage security rules | Yes |
| `lib/firebase_options.dart` | FlutterFire auto-generated config | **No** — run `flutterfire configure` |
| `android/app/google-services.json` | Android Firebase config | **No** — run `flutterfire configure` |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config | **No** — run `flutterfire configure` |

> **Note:** Android now uses `net.combofox.androidapp` as the package name.
> If you change it again, rerun `flutterfire configure` so Firebase service
> files match the new identifier.

## Legacy

The `old/` directory contains the original Python scripts that scraped web data
and generated a PDF magazine of Neo Geo games. It is kept for historical
reference. See [`old/README.md`](old/README.md).

## License

[MIT](LICENSE)
