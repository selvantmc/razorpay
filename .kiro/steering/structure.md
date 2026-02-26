# Project Structure

## Root Directory Layout
```
flutter_app/
├── lib/                    # Dart source code
├── test/                   # Unit and widget tests
├── android/                # Android platform code
├── ios/                    # iOS platform code
├── web/                    # Web platform code
├── build/                  # Build artifacts (generated)
├── .dart_tool/             # Dart tooling cache (generated)
├── pubspec.yaml            # Project dependencies and metadata
└── analysis_options.yaml   # Linting and analysis rules
```

## Source Code Organization (`lib/`)
- `main.dart`: Application entry point with `main()` function
- Organize features in subdirectories as the app grows (e.g., `lib/features/`, `lib/widgets/`, `lib/models/`)

## Testing (`test/`)
- Mirror the `lib/` structure in `test/`
- Use `_test.dart` suffix for test files (e.g., `widget_test.dart`)

## Platform-Specific Code
- `android/`: Gradle build files, Android manifests, Kotlin/Java code
- `ios/`: Xcode project, Info.plist, Swift/Objective-C code
- `web/`: HTML entry point and web-specific assets

## Code Style Conventions
- Use `const` constructors wherever possible (enforced by linter)
- Use `const` for immutable collections (enforced by linter)
- Follow official Flutter linting rules (`package:flutter_lints`)
- Use named parameters with `required` keyword for mandatory parameters
- Prefer `super.key` parameter for widget constructors
- Use Material 3 components and theming

## File Naming
- Use `snake_case` for file names (e.g., `my_widget.dart`)
- Use `PascalCase` for class names (e.g., `MyWidget`)
- Use `camelCase` for variables and functions (e.g., `myVariable`)

## Widget Organization
- Separate StatelessWidget and StatefulWidget into their own files when they grow beyond simple components
- Keep State classes private with underscore prefix (e.g., `_MyWidgetState`)
- Extract reusable widgets into separate files in a `widgets/` directory
