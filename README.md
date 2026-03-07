# Aipray - สวดมนต์อัจฉริยะ

AI-powered Buddhist chanting companion app with voice tracking, auto-scroll, and intelligent line matching.

## Features

- 20+ Buddhist chants (อิติปิโส, พาหุง, ชินบัญชร, มงคลสูตร, etc.)
- Voice recognition with auto-scroll tracking
- Round counter and session timer
- Prayer history with statistics
- Simulation mode for testing
- Beautiful dark temple-inspired theme (gold/amber)
- Offline-first design
- Cross-platform: Android, iOS, Web

## Tech Stack

- **Frontend**: Flutter 3.38+ / Dart 3.10+
- **ASR (planned)**: Sherpa-ONNX Thai model for on-device recognition
- **Backend (planned)**: xmanstudio (Laravel) for AI training data collection
- **AI Training (planned)**: Whisper Thai fine-tuning via HuggingFace

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Android/iOS
flutter run

# Build web
flutter build web --release

# Build Android APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/theme.dart            # Temple-inspired dark theme
├── models/
│   ├── chant.dart               # Chant & ChantLine models
│   └── prayer_session.dart      # Session tracking model
├── services/
│   ├── storage_service.dart     # Local persistence (SharedPreferences)
│   └── chant_matcher.dart       # Thai text matching algorithm
├── screens/
│   ├── main_shell.dart          # Bottom navigation shell
│   ├── home_screen.dart         # Dashboard with quick actions
│   ├── chant_list_screen.dart   # Browse & search chants
│   ├── chant_detail_screen.dart # View chant with font size control
│   ├── prayer_session_screen.dart # Active prayer with tracking
│   ├── history_screen.dart      # Prayer history & stats
│   └── settings_screen.dart     # App settings
└── data/chants/
    └── all_chants.dart          # 20+ Buddhist chant database
```

## Roadmap

- [ ] Phase 2: Sherpa-ONNX on-device speech recognition
- [ ] Phase 3: xmanstudio backend integration for data sync
- [ ] Phase 4: AI training pipeline (Whisper fine-tuning)
- [ ] Phase 5: App Store deployment (iOS + Android)

## Developer

Built by [xjanova](https://github.com/xjanova)
