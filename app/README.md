# ComboFox

an app to display moves lists in arcade fighting games such as NeoGeo and CPS2.

## Getting Started

This project is a Flutter application.

build the webapp:
```bash
cd app
flutter build web --release
```

deploy the app to web hosting:
```bash
firebase deploy --only hosting
```

## App Icons

Launcher icons are generated from `assets/logo.png` using [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons). The configuration is at the bottom of `pubspec.yaml`.

To regenerate icons after updating the source image:

```bash
dart run flutter_launcher_icons
```
