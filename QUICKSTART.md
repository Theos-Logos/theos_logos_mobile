# Quick Start Guide

Follow these steps to get your Theos Logos Mobile app up and running.

## Prerequisites

- Flutter SDK installed (check with `flutter --version`)
- An IDE (VS Code with Flutter extension, or Android Studio)
- Android Studio or Xcode (for emulators/simulators)

## Step-by-Step Setup

### Step 1: Navigate to your project location

```bash
cd /path/where/you/want/the/project
```

### Step 2: Create the Flutter project

```bash
flutter create theos_logos_mobile
cd theos_logos_mobile
```

### Step 3: Copy all files

Copy all the files from the provided package into your `theos_logos_mobile` directory, replacing the default files.

Your directory structure should look like:

```
theos_logos_mobile/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── router/
│   ├── screens/
│   └── widgets/
├── pubspec.yaml
├── README.md
└── ...
```

### Step 4: Get dependencies

```bash
flutter pub get
```

### Step 5: Run code generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

You should see output like:
```
[INFO] Generating build script completed, took 2.1s
[INFO] Creating build script snapshot completed, took 3.4s
[INFO] Building new asset graph completed, took 1.2s
[INFO] Succeeded after 1.5s with 6 outputs
```

### Step 6: Configure your manifest URL

Edit `lib/providers/manifest_provider.dart`:

```dart
// Change this line:
const String manifestUrl = 'YOUR_MANIFEST_URL_HERE';

// To your actual URL:
const String manifestUrl = 'https://your-domain.com/manifest.toml';
```

### Step 7: Run the app

```bash
flutter run
```

Or press F5 in VS Code.

## First Run

When you run the app for the first time:

1. The app will attempt to sync with your manifest URL
2. If successful, you'll see a list of available audio tracks
3. If there are new tracks, you'll see a "What's New" dialog
4. Tap any track to start streaming
5. Use the download button to save tracks for offline playback

## Developing

### Watch mode for code generation

Instead of running build_runner manually each time, you can run it in watch mode:

```bash
flutter pub run build_runner watch
```

This will automatically regenerate code when you save files.

### Hot reload

When the app is running, make changes to your code and press:
- `r` for hot reload (keeps app state)
- `R` for hot restart (resets app state)

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Run on specific device
flutter devices                    # List available devices
flutter run -d <device-id>        # Run on specific device

# Build release APK (Android)
flutter build apk --release

# Build release app bundle (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

## Testing Your Manifest

Create a test `manifest.toml` file:

```toml
[[files]]
id = "test-001"
title = "Test Audio 1"
file_name = "test1.mp3"
url = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
date_added = "2025-10-01T10:00:00Z"

[[files]]
id = "test-002"
title = "Test Audio 2"
file_name = "test2.mp3"
url = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"
date_added = "2025-10-15T10:00:00Z"
```

Host this file somewhere accessible and update your `manifestUrl` to point to it.

## Troubleshooting

### "Command not found: flutter"
- Ensure Flutter is in your PATH
- Run `flutter doctor` to check your setup

### Build runner errors
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Unable to find ManifestNotifier"
- Make sure you've run the build_runner command
- Check that `.g.dart` files exist next to your provider files

### App crashes on startup
- Check your manifest URL is correct and accessible
- Look at the console logs for specific errors
- Ensure all dependencies are installed (`flutter pub get`)

## Next Steps

1. ✅ Get the app running
2. 📝 Customize the UI theme
3. 🔊 Test audio playback
4. 💾 Test offline downloads
5. 🚀 Build and distribute

Need help? Check the full README.md for detailed documentation.
