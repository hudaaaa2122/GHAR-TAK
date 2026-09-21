# Gher Tak Mobile (Flutter)

Customer Android/iOS app for Gher Tak.

## Setup

1. Install Flutter 3.24+
2. From this folder:

```bash
flutter pub get
flutter run
```

## Config

Edit `lib/core/config/app_config.dart` (or pass `--dart-define=API_BASE_URL=...`):

- Android emulator → host: `http://10.0.2.2:8000`
- Physical device on LAN: your PC IP + `:8000`

## Structure

```
lib/
  core/       theme, config, network, storage
  data/       models, repositories
  features/   screens by domain
  shared/     reusable widgets
  router/     go_router
```

## Build Android release

```bash
flutter build apk --release
```
