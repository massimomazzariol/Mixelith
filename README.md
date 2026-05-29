# Mixelith

Mixelith is a Flutter app for privacy-first artistic photo filters. It focuses on local images, graphic and abstract transformations, and exports that avoid carrying over sensitive metadata.

Mixelith is being shaped toward its first 0.1.0 milestone. The product target is Android, while Windows desktop is supported as a development preview for quick UI checks.

## What It Does

- Capture a photo or select local photos from the Android gallery.
- Apply procedural artistic filters such as neon, watercolor, mosaic, oil-inspired and poster looks.
- Compare original and modified previews.
- Export JPEG or PNG results back to the gallery.
- Re-encode exports so original image metadata is not carried over.

## Principles

- Local processing first.
- No account.
- No tracking or analytics.
- No ads.
- No backend.
- No Firebase.
- No machine learning in 0.1.0.
- No share sheet in 0.1.0.
- No `android.permission.INTERNET`.

## Development Status

Mixelith is being shaped toward its first 0.1.0 milestone. Detailed progress is tracked in [BACKLOG.md](BACKLOG.md) and [docs/ROADMAP.md](docs/ROADMAP.md).

## Development Targets

- Android: product target for 0.1.0 and the only target for real photo permissions/gallery behavior.
- Windows desktop: development preview target with placeholder media for fast UI iteration.

## Requirements

- Flutter SDK.
- Android SDK / Android Studio.
- Android emulator or Android device for real gallery testing.
- Visual Studio with Desktop development with C++ for Windows desktop builds.

## Setup

```bash
git clone https://github.com/massimomazzariol/Mixelith.git
cd Mixelith
flutter pub get
```

## Run

```bash
flutter run -d windows
flutter run -d <android-device-id>
```

## Checks

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

## Project Structure

```text
lib/
|-- app/
|-- core/
|-- features/
|-- filters/
|-- media/
`-- storage/
docs/
android/
test/
```

## Documentation

- [Product specification](docs/PRODUCT_SPEC.md)
- [Technical specification](docs/TECH_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Filter system](docs/FILTER_SYSTEM.md)
- [Dependency decisions](docs/DEPENDENCY_DECISIONS.md)
- [Privacy and offline policy](docs/PRIVACY_AND_OFFLINE.md)
- [Roadmap](docs/ROADMAP.md)
- [Testing guide](docs/TESTING.md)
- [Development guidelines](docs/DEVELOPMENT_GUIDELINES.md)
- [UI reference](docs/UI_REFERENCE.md)
- [Worklog](docs/WORKLOG.md)
