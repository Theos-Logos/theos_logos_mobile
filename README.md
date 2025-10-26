# Theos Logos Mobile

A Flutter audio player application for Theos Logos content with offline support and automatic syncing.

## Features

- ✅ Sync with remote `manifest.toml` on app start
- ✅ Download audio files for offline playback
- ✅ Display "What's New" when manifest is updated
- ✅ Remember playback position (continue where you stopped)
- ✅ Sort files by order specified in manifest
- ✅ Stream or play downloaded files
- ✅ Modern state management with Riverpod
- ✅ Navigation with go_router

## Setup Instructions

### 1. Create the Flutter project

Since Flutter is already installed on your machine, run:

```bash
flutter create --project-name theos_logos_mobile .
```

This will initialize the Flutter project in the current directory.

### 2. Replace the generated files

Copy all the files from this package to your project directory, replacing the generated ones.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Generate Riverpod code

Riverpod uses code generation. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the following files:
- `lib/router/app_router.g.dart`
- `lib/providers/manifest_provider.g.dart`
- `lib/providers/audio_provider.g.dart`

You'll need to run this command whenever you modify any file with the `part 'filename.g.dart';` declaration.

### 5. Configure your manifest URL

Open `lib/providers/manifest_provider.dart` and replace:

```dart
const String manifestUrl = 'YOUR_MANIFEST_URL_HERE';
```

with your actual manifest URL, for example:

```dart
const String manifestUrl = 'https://example.com/manifest.toml';
```

### 6. Manifest Format

Your `manifest.toml` should follow this format:

```toml
[[files]]
id = "track-001"
title = "Introduction to Theology"
file_name = "01-introduction.mp3"
url = "https://example.com/audio/01-introduction.mp3"
date_added = "2025-01-15T10:00:00Z"

[[files]]
id = "track-002"
title = "Understanding Scripture"
file_name = "02-scripture.mp3"
url = "https://example.com/audio/02-scripture.mp3"
date_added = "2025-01-20T10:00:00Z"
```

The order in the manifest determines the display order.

## Running the App

### Android

```bash
flutter run
```

### iOS

```bash
flutter run
```

### Development Tips

1. **Hot Reload**: When you make changes, press `r` in the terminal for hot reload
2. **Code Generation**: Run `flutter pub run build_runner watch` to automatically regenerate code on changes
3. **Clean Build**: If you encounter issues, try `flutter clean && flutter pub get`

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── audio_track.dart              # Audio track data model
├── providers/
│   ├── audio_provider.dart           # Audio player state management
│   └── manifest_provider.dart        # Manifest syncing and downloads
├── router/
│   └── app_router.dart               # App navigation routes
├── screens/
│   └── playlist_screen.dart          # Main playlist screen
└── widgets/
    └── audio_player_widget.dart      # Audio player controls widget
```

## Architecture

- **State Management**: Flutter Riverpod with code generation
- **Navigation**: go_router for declarative routing
- **Audio Playback**: just_audio for cross-platform audio
- **Persistence**: shared_preferences for settings and state
- **HTTP**: http package for downloading files
- **TOML Parsing**: toml package for manifest parsing

## Next Steps

1. Customize the UI theme in `main.dart`
2. Add more screens (settings, track details, etc.)
3. Implement background audio playback
4. Add playlist management features
5. Implement search functionality

## Troubleshooting

### Build runner issues

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Audio not playing

- Check that the manifest URL is correct
- Ensure the audio file URLs are accessible
- Verify internet connection for streaming
- Check app permissions for file storage

### Dependencies issues

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## License

This project is for Theos Logos content distribution.
