# Finance Planner

An offline-first personal finance planner built with Flutter.

## Architecture

- Feature-first project structure.
- MVVM presentation with Flutter's native `ChangeNotifier`.
- GetIt for dependency injection.
- GoRouter for navigation.
- Drift for local SQLite persistence.
- Shared light/dark Material 3 design system.

## Local development

Use a stable Flutter SDK that satisfies the Dart SDK constraint in `pubspec.yaml`.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
flutter run
```

Drift generates `lib/core/database/app_database.g.dart` from the annotated database and table declarations. Regenerate it whenever those declarations change.

## Git workflow

- `master`: stable branch; do not develop directly on it.
- `dev`: integration branch.
- `feature/*`: short-lived feature branches created from `dev`; pull requests target `dev`.

Never target `master` with feature pull requests during active development.

## Current foundation

The initial app shell contains Home, Calendar, Money, Work and Plan destinations. These are temporary placeholders for feature implementation. Financial features will be added incrementally with domain contracts, data implementations, ViewModels and tests.
