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

> **Note:** The Android `applicationId` and iOS bundle identifier still read
> `com.otakuplaybook.otaku_playbook` to preserve the existing Firebase app
> registrations and Play Store identity. A future migration PR will rename
> them alongside a Firebase re-registration.

## Legacy

The `old/` directory contains the original Python scripts that scraped web data
and generated a PDF magazine of Neo Geo games. It is kept for historical
reference. See [`old/README.md`](old/README.md).

## License

[MIT](LICENSE)
