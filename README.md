# Netlify Messenger

A cross-platform messaging app by Netlify Network. Development starts with the Windows desktop experience.

## Current milestone

- WhatsApp-inspired desktop layout
- Dark and light themes
- Local demo conversations and message composer
- Chat search and navigation
- No hosting or deployment service is required

> The current UI is a frontend prototype. Authentication, cloud sync, real-time messaging, media uploads, and voice/video calls will be connected in later milestones.

## Run on Windows

1. Install Flutter and Visual Studio 2022 with **Desktop development with C++**.
2. Open a terminal in this repository.
3. Run:

```powershell
flutter create --platforms=windows .
flutter pub get
flutter run -d windows
```

Build a Windows release:

```powershell
flutter build windows --release
```

The release output is under `build/windows/x64/runner/Release` (or the architecture-specific runner folder).

## Project structure

- `lib/main.dart` — application entry point and Windows-first UI
- `pubspec.yaml` — Flutter project metadata

## Planned milestones

1. Windows UI prototype
2. Supabase phone OTP and user profiles
3. Real-time one-to-one and group messaging
4. Media and voice messages
5. Voice/video calls
6. Android, Linux, macOS and web support
