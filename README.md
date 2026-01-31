# Phone Roulette

A Flutter app that randomly selects and calls contacts from a weighted subset. Perfect for small screens like the Unihertz Jelly 2E.

## Features

- **Contact Selection**: Search and select which contacts to include in the roulette
- **Weighted Selection**: Rate contacts 1-10 for closeness - higher ratings mean more "raffle tickets"
- **Spin to Call**: Press the spin button to randomly select a contact, with 3 seconds to cancel before calling
- **Call History**: Track who you've called and when, with statistics

## Getting Started

### Prerequisites

- Flutter SDK (3.8.0+)
- Android SDK
- A physical Android device (for testing with real contacts)

### Using Nix

This project includes a `shell.nix` for easy development environment setup:

```bash
nix-shell
flutter pub get
flutter run
```

### Without Nix

```bash
flutter pub get
flutter run
```

## Building for Release

```bash
nix-shell --run "flutter build apk --release"
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

## Permissions

The app requires:
- **READ_CONTACTS**: To access your phone contacts
- **CALL_PHONE**: To initiate phone calls

## Usage

1. **Select Tab**: Search and check contacts to add to your roulette pool
2. **Rate Tab**: Adjust the closeness slider (1-10) for each contact
   - 1 = Acquaintance (fewer chances)
   - 10 = Best Friend (more chances)
3. **Spin Tab**: Press SPIN to randomly select a contact
   - You have 3 seconds to CANCEL before the call is made
4. **Stats Tab**: View your call history and statistics

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── roulette_contact.dart    # Contact data model
│   └── call_log_entry.dart      # Call log data model
├── services/
│   ├── database_service.dart    # SQLite database operations
│   ├── contacts_service.dart    # Phone contacts access
│   └── roulette_service.dart    # Weighted selection logic
└── pages/
    ├── select_contacts_page.dart
    ├── rate_contacts_page.dart
    ├── roulette_page.dart
    └── stats_page.dart
```

## Data Storage

All data is stored locally using SQLite:
- Selected contacts and their closeness ratings
- Call history log

No internet connection or account required.

## License

MIT License
