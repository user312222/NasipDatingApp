<div align="center">

# Bi Nasip

**A Turkish-first, marriage-first, privacy-first matchmaking app for Muslim singles.**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)

</div>

---

## About

**Bi Nasip** ("everyone has a share/destiny") is a closed-beta dating app for people who are looking to **marry**, not to swipe endlessly. Its design choices follow from that:

- **Intent is stated up front** — every profile says whether the person is looking for marriage or is not sure yet.
- **Privacy by default** — photos are hidden until the owner opens them; people appear as gradient + initial-letter avatars rather than faces.
- **Family can be involved, on the user's terms** — a relative can link to an account with an invite code and sees *only* the matches the user explicitly marked "show my family" (never messages, photos or contact info).
- **KVKK (Turkish data-protection law) aware** — explicit consent screens, account deletion, no raw selfie/biometric data kept.

The UI is Turkish only (v1). The product spec lives in [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) (also Turkish); a more formal [`docs/SRS.md`](docs/SRS.md) (Turkish, IEEE 830-style) is derived from it for readers who want inputs/outputs/acceptance criteria spelled out per requirement.

> **Status: work in progress / closed beta.** Some parts are real, some are still placeholders. See [What is real vs mock](#what-is-real-vs-mock) before assuming something works end to end.

---

## Features

| Area | What it does |
| --- | --- |
| **Onboarding** | Invite gate → account type (single / relative) → KVKK consent → phone + SMS OTP → liveness step → 5-step profile wizard |
| **Discovery** | Swipeable candidate card (drag or buttons), filters (city, age range, intent), daily like cap, match celebration |
| **Matches & chat** | Matches list with last-message preview, 1:1 text chat, one-time gentle "involve your family?" nudge |
| **Privacy** | Per-user photo visibility (hidden / on request / on match), optional religious details behind a separate KVKK m.6 consent |
| **Family** | Invite code for a relative, per-match "show my family" switch, read-only guardian view |
| **Safety** | Report and block from the card menu and the chat, account deletion, log out |
| **Waitlist** | Public waitlist page for people without an invite code |

---

## What is real vs mock

| Piece | State |
| --- | --- |
| Phone + SMS OTP sign-in, session restore, log out | **Real** (Firebase Auth) |
| Profiles, likes, matches, messages, reports, blocks, family links, consent records, account deletion | **Real** (Cloud Firestore, rules in [`firestore.rules`](firestore.rules)) |
| Invite code check | **Mock** — a single hard-coded beta code |
| Selfie / liveness verification | **Mock** — always succeeds; no camera is opened. A third-party provider is planned |
| Photo upload | **Not implemented** — photos are picked and shown locally but not stored; people are shown as initial-letter avatars |
| Photo moderation | **Mock** — filename heuristic only |
| Waitlist submissions | **Local only** — not sent to a backend |
| Real-time chat | **No** — messages are fetched when a conversation is opened (no live listener) |
| Push notifications | **No** |
| KVKK consent text | **Draft** — needs a lawyer's review before real users see it (see `docs/REQUIREMENTS.md` §7) |

The project runs on the Firebase **Spark (free) plan**, so there are no Cloud Functions. A few rules are therefore enforced client-side or by Firestore rules alone; the known gaps are documented next to the code in `firestore.rules` and the `Firestore*RemoteDataSource` classes.

---

## Tech stack

- **Framework:** [Flutter](https://flutter.dev/) (Material 3), Dart
- **Backend:** Firebase — Authentication (phone), Cloud Firestore
- **State management:** BLoC / Cubit (`flutter_bloc`), `equatable`
- **Dependency injection:** `get_it`
- **Routing:** `go_router`
- **Fonts:** Fraunces (display) and Sora (UI) via `google_fonts`

### Architecture

Feature-first clean architecture. Each feature under `lib/features/<name>/` has `data/`, `domain/` and `presentation/` layers:

- **domain** — entities, repository interfaces, use cases (no Flutter/Firebase imports)
- **data** — repository implementations and remote data sources (`Firestore*` for real backends, `Mock*` for placeholders — swapped in `lib/core/di/injection_container.dart`)
- **presentation** — cubits/states and screens

Calls that can fail return a `Result<T>` (`Ok` / `Err` with a typed `Failure`) instead of throwing across layers. Shared code lives in `lib/core/` (errors, `Result`, formatting, restart helper) and `lib/theme/` (design tokens and shared widgets).

### Design system

"Gece Moru" palette (plum / brass / rose on warm cream) with light and dark themes. Tokens are in `lib/theme/app_colors.dart`; shared widgets (`WizardBackdrop`, `WizardHeader`, `GradientButton`, `OptionCard`, `SectionCard`) are in `lib/theme/wizard_widgets.dart`. Run the app and open **`/design-preview`** for a live gallery with a light/dark switch.

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; see `pubspec.yaml` for the Dart constraint)
- A browser (Chrome) for web, or an Android/iOS device or emulator
- For your own Firebase project: the [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)

### Run

```bash
flutter pub get
flutter run -d chrome        # or any connected device
```

`lib/firebase_options.dart` points at the project's Firebase app. To use **your own** Firebase project instead, run `flutterfire configure`, enable **Phone** sign-in and **Firestore** (region `eur3` was used), then deploy the rules:

```bash
firebase deploy --only firestore:rules --project <your-project-id>
```

Sign-in uses SMS. For development, add **test phone numbers** in *Firebase Console → Authentication → Sign-in method → Phone → Phone numbers for testing* (e.g. `+90 555 000 00 00` with code `123456`) so no real SMS is sent. The beta invite code is defined in `MockAuthRemoteDataSource` (`lib/features/auth/data/datasources/auth_remote_data_source.dart`).

### Serving a production web build

```bash
flutter build web
node tools/serve_web.js      # serves build/web on http://localhost:8766
```

### Tests and analysis

```bash
flutter analyze
flutter test
```

The tests cover the matches cubit, the shared widgets, the chat timestamp formatter, the design gallery and an app-boot smoke test. Firestore-backed screens are verified manually against a real project — there is no emulator-based suite yet.

---

## Project layout

```
lib/
  core/        errors, Result, DI container, router, formatting, app restart
  features/    account · auth · consent · family · matching · messaging
               · profile · safety · waitlist   (data / domain / presentation)
  screens/     developer-only design gallery (/design-preview)
  theme/       colors, text styles, theme, shared widgets
docs/          REQUIREMENTS.md — product spec, decisions and open items
               SRS.md — formal requirements spec derived from REQUIREMENTS.md
firestore.rules  security rules (default deny)
```

---

## Roadmap / known gaps

See [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) §7 for open decisions. The main gaps are real photo upload and storage, a real selfie-verification provider, unread indicators and live updates in chat, and legal review of the consent text.
