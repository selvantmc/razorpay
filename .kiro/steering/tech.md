# Technology Stack

## Framework & Language
- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Material 3 design components

## Dependencies
- `cupertino_icons`: iOS-style icons
- `flutter_lints`: Official Flutter linting rules

## Build System
Flutter's native build system with platform-specific tooling (Gradle for Android, Xcode for iOS).

## Common Commands

### Setup
```bash
flutter pub get              # Install dependencies
flutter doctor              # Check Flutter installation
```

### Development
```bash
flutter run                 # Run app in debug mode
flutter run --release       # Run in release mode
flutter run -d <device>     # Run on specific device
```

### Testing
```bash
flutter test                # Run unit and widget tests
flutter test --coverage     # Run tests with coverage
```

### Building
```bash
flutter build apk           # Build Android APK
flutter build appbundle     # Build Android App Bundle
flutter build ios           # Build iOS app
flutter build web           # Build web app
```

### Code Quality
```bash
flutter analyze             # Run static analysis
dart format .               # Format code
dart fix --apply            # Apply automated fixes
```

### Cleaning
```bash
flutter clean               # Clean build artifacts
flutter pub cache repair    # Repair pub cache
```
