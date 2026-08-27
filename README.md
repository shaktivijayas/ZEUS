<div align="center">

```
_________________________ ___  _________
\____    /\_   _____/    |   \/   _____/
  /     /  |    __)_|    |   /\_____  \
 /     /_  |        \    |  / /        \
/_______ \/_______  /______/ /_______  /
        \/        \/                 \/

   calm training & nutrition logbook  ·  flutter + firebase  ·  android
```

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-3B5BDB?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)
[![Material 3](https://img.shields.io/badge/Material%203-757575?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)

![License](https://img.shields.io/badge/License-Unlicensed-lightgrey?style=flat-square)
![Status](https://img.shields.io/badge/Status-Phases%201--2%20Shipped-brightgreen?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square)
![Tests](https://img.shields.io/badge/Tests-134%20passing-00d4ff?style=flat-square)

</div>

---

## ⚡ What is ZEUS?

**ZEUS** is a gym + nutrition companion app for its creator plus a small group of friends and family who train and eat with intention. It's opened **mid-workout or right after a meal** — never for a "session" — so every screen is built around one narrow job: log a check-in, complete today's split, or log a meal, then get out of the way.

It's an **Android-only Flutter app**, delivered as a shareable APK (`flutter build apk`) rather than through the Play Store, developed in four phases:

| Phase | Scope | Status |
|:---|:---|:---|
| **1** | Foundation · auth · split / workout tracking · check-in streak with freezes | ✅ Shipped |
| **2** | Calorie & macro tracking — TDEE goal, Open Food Facts search, manual entry | ✅ Shipped |
| **3** | Reminders (Firebase Cloud Messaging) | 🔜 Planned |
| **4** | Social — friends, shared streaks, chat | 🔜 Planned |

> A calm, honest logbook for training and eating — not a coach shouting at you, not a game keeping score.

Phase 2 is deliberately **independent** of Phase 1: logging food never touches your streak, and the streak algorithm never looks at food.

---

## 📸 Screenshots

> Real captures from a debug build running on an Android 14 emulator (Pixel 7).

| Sign up | Home / Summary |
|:---:|:---:|
| <img src="docs/screenshots/01-auth.png" width="280" /> | <img src="docs/screenshots/03-home.png" width="280" /> |

---

## ✨ Features

### Training

- 📅 **Weekly split editor** — one configurable workout per weekday (Mon–Sun); each day has a label and an ordered list of exercise targets (sets, reps, weight). Unconfigured days render as rest days.
- ✅ **One-tap check-in** — grants streak credit *immediately*, decoupled from whether you log any exercises afterward.
- 📝 **Autosaving workout logs** — a `draft` is created the moment you tick your first exercise; every later edit autosaves, so backing out mid-session loses nothing. **Finish** flips the draft to `completed` and records untouched exercises as `skipped`.
- ❄️ **Streak freezes** — 2 per month (auto-reset). A missed day silently spends a freeze instead of breaking the streak; once freezes run out, the streak resets to 0.
- 🌙 **Rest days** — pre-mark a day from the calendar; the streak algorithm then skips it without spending a freeze.
- 📈 **Split history** — per split day, an `fl_chart` line chart of total training **volume** (`sets × reps × weight`) across every completed session.

### Nutrition

- 🔥 **TDEE calorie goal** — a Mifflin–St Jeor calculator (weight, height, age, sex, activity level, goal) produces a daily `calorieGoal` and a 30 / 40 / 30 protein / carb / fat macro split. Inputs are saved and re-editable.
- 🍽️ **Daily food log** — entries grouped into Breakfast / Lunch / Dinner / Snacks with per-meal subtotals and a running total against your goal ("1,450 / 2,200 kcal").
- 🔎 **Two entry paths, one save** — **Search** a debounced [Open Food Facts](https://world.openfoodfacts.org) query (no API key), pick a result, enter grams, and per-100 g figures are scaled to totals; or **Manual** — type the name and totals directly for home-cooked food.
- ⚡ **Recently-logged quick-add** — computed client-side from your own last 7 days of entries; no separate food-catalog collection.
- 📌 **Snapshotted entries** — full nutrition is embedded in each entry at save time, so editing a food later never rewrites history.

### Cross-cutting

- 📴 **Offline-first** — Firestore's local cache means check-ins, workout logs and manual food entries all work at the gym with no signal; writes sync on reconnect. A banner shows offline state (`connectivity_plus`).
- 🔐 **Auth-gated navigation** — `go_router` redirects enforce `signed out → /auth`, `new → /onboarding`, `onboarded → /home`, reacting live to `FirebaseAuth` state.

---

## 🛠️ Tech Stack

| Layer | Technology |
|:---|:---|
| **Language / SDK** | Dart 3.12, Flutter 3.12+ |
| **UI** | Material 3 (`useMaterial3: true`), light + dark `ColorScheme`, `ThemeMode.system` |
| **State management** | Riverpod (`flutter_riverpod`) + constructor injection via the router |
| **Routing** | go_router — declarative routes + async redirect guard + `refreshListenable` on the auth stream |
| **Auth** | Firebase Auth (email / password) |
| **Database** | Cloud Firestore — offline persistence, per-user document tree, security rules + composite indexes in repo |
| **Networking** | `http` → Open Food Facts `/api/v2/search` |
| **Charts** | `fl_chart` — split-day volume progression |
| **Connectivity** | `connectivity_plus` — offline banner |
| **Fonts / icons** | `google_fonts` (Inter), `cupertino_icons`, `font_awesome_flutter` |
| **Testing** | `flutter_test`, `mocktail`, `fake_cloud_firestore`, `firebase_auth_mocks` — 134 tests |
| **Rules tests** | Node + `@firebase/rules-unit-testing` (Jest) in `firestore-tests/` |

---

## 🏗️ Architecture

ZEUS is a **layered single-module Flutter app**. Widgets never touch Firestore directly — every read/write goes through a repository, and every non-trivial rule (streak math, TDEE math, nutrition scaling) is extracted into a **pure function** that is unit-tested without Firebase.

```mermaid
flowchart TD
    subgraph Device["📱 Android device"]
        main["main.dart<br/>Firebase.initializeApp()"]
        app["ZeusApp<br/>MaterialApp.router · light/dark theme · offline banner"]
        router["appRouter (go_router)<br/>redirect guard + auth refresh stream"]

        subgraph Features["lib/features — one folder per screen"]
            auth[Auth]
            onb[Onboarding]
            home[Home / Summary + HomeSyncGate]
            split[Split Editor / Day Detail]
            hist[Split History]
            cal[Calendar]
            food[Calorie Log / Add Food]
            goal[Calorie Goal]
            prof[Profile]
        end

        subgraph Core["lib/core — cross-cutting"]
            repos["firestore/*Repository<br/>user · split · checkIn · workoutLog · foodLog"]
            svc["services<br/>CheckInService · AppOpenSyncService"]
            pure["pure domain logic<br/>runGapWalk() · calculateTdeeGoal()"]
            search["FoodSearchRepository"]
            conn["ConnectivityService"]
            theme["theme/ tokens"]
        end

        models["lib/models — plain Dart data classes (fromMap/toMap)"]
    end

    subgraph Cloud["☁️ Firebase project"]
        fauth["Firebase Auth<br/>email / password"]
        fs["Cloud Firestore<br/>users/{uid}/... + rules + indexes"]
    end

    ext["🌐 Open Food Facts API<br/>world.openfoodfacts.org"]

    main --> app --> router --> Features
    Features --> repos
    Features --> svc
    svc --> pure
    svc --> repos
    Features --> search
    repos --> models
    repos <--> fs
    router <--> fauth
    Features --> conn
    search --> ext
```

### Auth & onboarding redirect flow

```mermaid
stateDiagram-v2
    [*] --> CheckAuth: any navigation
    CheckAuth --> AuthScreen: no signed-in user
    CheckAuth --> LoadUserDoc: user signed in
    LoadUserDoc --> Onboarding: onboarded == false
    LoadUserDoc --> Home: onboarded == true
    AuthScreen --> LoadUserDoc: sign up / sign in succeeds
    Onboarding --> Home: first split day saved (onboarded := true)
    Home --> AuthScreen: sign out
```

### App-open sync (streak) sequence

```mermaid
sequenceDiagram
    participant U as User opens app
    participant G as HomeSyncGate
    participant S as AppOpenSyncService
    participant W as runGapWalk() (pure)
    participant CR as CheckInRepository
    participant UR as UserRepository
    participant FS as Firestore

    U->>G: navigate to /home
    G->>S: sync()  (Home blocked until done)
    S->>UR: getUser()
    S->>CR: getLastActivityDate(today)
    S->>CR: getCheckInsInRange(last, today)
    S->>W: runGapWalk(lastActivity, today, streak, freezes, …)
    W-->>S: writes[]  +  newStreak  +  newFreezes
    alt gap detected
        S->>CR: writeCheckIns(freeze_used / missed docs)
        S->>UR: updateStreakAndFreezes(...)
    end
    S-->>G: done
    G-->>U: Home is now interactive
```

---

## 🗄️ Data Model

All data lives under a single per-user document tree in Firestore. Date-keyed documents (`YYYY-MM-DD` as the **document ID**) are the idempotency mechanism — the same day can only ever have one check-in / food-log doc.

```mermaid
erDiagram
    USER ||--o{ SPLIT_DAY : "has (Mon–Sun)"
    USER ||--o{ CHECK_IN : "one per date"
    USER ||--o{ WORKOUT_LOG : "one per session"
    USER ||--o{ FOOD_LOG : "one per date"
    CHECK_IN ||..o| WORKOUT_LOG : "workoutLogId"

    USER {
        string name
        string email
        datetime createdAt
        int currentStreak
        int longestStreak
        int freezesRemaining "resets 2/month"
        datetime freezesResetDate
        bool onboarded
        int calorieGoal "nullable"
        map macroGoals "nullable {protein,carbs,fat}"
        map tdeeProfile "nullable saved inputs"
    }
    SPLIT_DAY {
        string label
        int order
        array exercises "{name,targetSets,targetReps,targetWeight,order}"
    }
    CHECK_IN {
        string id "YYYY-MM-DD"
        string type "checked_in | rest_day | freeze_used | missed"
        datetime timestamp
        string workoutLogId "nullable"
    }
    WORKOUT_LOG {
        string date
        string splitDayId
        string status "draft | completed"
        array exercises "targets + actualSets/Reps/Weight + status + notes"
        datetime completedAt "nullable"
    }
    FOOD_LOG {
        string id "YYYY-MM-DD"
        map meals "breakfast[] lunch[] dinner[] snacks[]"
    }
```

**Food entry** (embedded in `foodLogs/{date}.meals.*`):

```jsonc
{
  "name": "Greek yogurt",
  "calories": 130,          // total for the entry, already scaled — never per-100g
  "protein": 11, "carbs": 8, "fat": 4,
  "quantity": 150,          // grams — set for openfoodfacts entries, null for manual
  "unit": "g",              // null for manual
  "source": "openfoodfacts", // or "manual"
  "loggedAt": "2026-08-05T09:12:00Z"
}
```

Security rules (`firestore.rules`): every document under `users/{uid}` is readable/writable **only** by `request.auth.uid == uid`. Composite indexes (`firestore.indexes.json`) back the completed-workout-by-split-day query and the descending check-in lookup.

---

## 🧠 How the Hard Parts Work

### 1. Idempotent check-in

`checkIns/{date}` uses the **calendar date string as the document ID**, not an auto-ID. Tapping "Check In" runs a Firestore **transaction** that:

1. reads today's check-in doc — if it already exists as `checked_in`, returns (no double streak credit);
2. otherwise writes the `checked_in` doc **and** bumps `currentStreak` / `longestStreak` atomically.

`currentStreak` is a stored counter but is only ever mutated inside this transaction (or the gap-walk), never incremented by a raw button tap, so double-tapping is harmless.

### 2. The streak gap-walk (freezes)

`runGapWalk()` in `lib/core/streak/gap_walk.dart` is a **pure function** of
`(lastActivityDate, today, currentStreak, freezesRemaining, freezesResetDate, existingCheckIns) → (writes[], newStreak, newFreezesRemaining, newFreezesResetDate)`.

On every app open, `AppOpenSyncService.sync()` runs it and `HomeSyncGate` blocks the Home screen until it finishes, so a "Check In" tap can never race the sync:

1. **Monthly freeze reset first** — if `freezesResetDate` has passed, `freezesRemaining` is reset to 2 and the date advanced one month (with day-clamping so Jan 31 → Feb 28). Ordering matters: a stale low freeze count must not cause a wrongful `missed` day.
2. **Walk each date** from the day after `lastActivityDate` through yesterday, oldest first:
   - a doc already exists (e.g. a pre-marked rest day) → skip, touch nothing;
   - no doc, `freezesRemaining > 0` → write `freeze_used`, decrement;
   - no doc, no freezes → write `missed`, set streak `0`, keep walking (remaining `missed` days are cosmetic).
3. **Today stays open** — checking in today makes the streak `1` (if it just broke) or increments normally.

Because it is pure, the whole freeze/streak matrix is unit-tested with zero Firebase.

### 3. TDEE & macro goal

`calculateTdeeGoal()` in `lib/core/nutrition/tdee_calculator.dart`:

```
BMR   = 10·kg + 6.25·cm − 5·age + (male ? +5 : −161)          // Mifflin–St Jeor
TDEE  = BMR × activityMultiplier                              // 1.2 … 1.9
goal  = TDEE − 500 (lose) | TDEE (maintain) | TDEE + 300 (gain)
macros = 30% protein / 40% carbs / 30% fat  →  grams at 4/4/9 kcal·g⁻¹
```

No network, no API — fully offline and unit-tested per branch.

### 4. Open Food Facts search

`FoodSearchRepository` wraps the free `/api/v2/search` endpoint (descriptive `User-Agent` per their policy, 10 s timeout). Results missing a usable calorie/macro figure are dropped rather than shown broken. A picked result's per-100 g figures are scaled by the entered grams (`value × qty / 100`) into a `FoodEntry` with totals — the **same shape** manual entry produces, so both paths share one save.

---

## 📂 Project Structure

```
lib/
├── main.dart                     # Firebase init + ZeusApp (MaterialApp.router)
├── core/
│   ├── auth/                      # AuthRepository, Riverpod providers
│   ├── checkin/                   # CheckInService (transactional check-in)
│   ├── connectivity/             # ConnectivityService + offline banner
│   ├── firebase/                  # generated firebase_options.dart
│   ├── firestore/                 # *Repository — user, split, checkIn, workoutLog, foodLog
│   ├── nutrition/                 # tdee_calculator.dart, food_search_repository.dart
│   ├── router/                    # app_router.dart, go_router_refresh_stream.dart
│   ├── streak/                    # gap_walk.dart  (pure streak algorithm)
│   ├── sync/                      # app_open_sync_service.dart
│   ├── theme/                     # ColorScheme + spacing + typography tokens, mockup palettes
│   └── widgets/                   # AppleBottomBar (shared frosted tab bar)
├── features/                      # auth · onboarding · home · calendar · calories · split_editor · split_history · profile
└── models/                        # AppUser, SplitDay, CheckIn, WorkoutLog, FoodLog, FoodEntry, MacroGoals, TdeeProfile, …

test/                             # 134 tests mirroring lib/  (fake_cloud_firestore + firebase_auth_mocks)
firestore-tests/                  # Node/Jest security-rules suite
android/                          # Gradle Kotlin DSL, google-services.json
docs/superpowers/                 # phase specs + implementation plans
firestore.rules · firestore.indexes.json · firebase.json
DESIGN.md · PRODUCT.md            # design system + product brief
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK ≥ 3.12** (Dart 3.12) — `flutter doctor` clean for the Android toolchain
- **Android SDK** + an emulator or physical device (`adb devices`)
- A **Firebase project** with **Email/Password** auth and **Cloud Firestore** enabled

### Installation

```bash
git clone https://github.com/shaktivijayas/ZEUS.git
cd ZEUS
flutter pub get
```

### Firebase configuration

The repo already contains a working config for the original project
(`android/app/google-services.json`, `lib/core/firebase/firebase_options.dart`).
To point a fork at **your own** Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure          # regenerates firebase_options.dart + google-services.json

npm install -g firebase-tools
firebase deploy --only firestore:rules,firestore:indexes
```

### Run

```bash
flutter run                              # debug, on the connected device/emulator
flutter build apk --release              # shareable APK → build/app/outputs/flutter-apk/
```

On first launch: **Sign up** → create your **first split day** (this flips `onboarded`) → you land on Home. Set a calorie goal from **Profile → Set calorie goal** to activate the nutrition progress display.

---

## 🧪 Testing

```bash
flutter test                             # 134 unit + widget tests

# Firestore security-rules suite (needs the Firebase emulator)
cd firestore-tests
npm install
firebase emulators:exec --only firestore "npm test"
```

| Layer | Approach |
|:---|:---|
| **Pure functions** (`runGapWalk`, `calculateTdeeGoal`, nutrition scaling) | exhaustive branch coverage, no Firebase |
| **Repositories** | run against `fake_cloud_firestore` |
| **Auth** | `firebase_auth_mocks` |
| **Widgets** | every screen has a test for its core behaviour (meal grouping & subtotals, *visible* validation errors, chip colours from `ColorScheme`, rest-day rendering…) |
| **Rules** | `@firebase/rules-unit-testing` verifies cross-user reads/writes are denied |

---

## 🎨 Design System

`DESIGN.md` defines **"The Lab Notebook"**: one forest-green accent used on ≤10 % of any screen, flat tonal surfaces (no resting shadows), a single typeface (Roboto) carrying hierarchy through weight/size alone, tabular figures for numbers, and a deliberately re-toned **dark `ColorScheme`**. Accessibility baseline is WCAG AA contrast + respect for the system font-scale.

> **Note on visual drift:** the shipped app currently mixes two looks. The original Material-3 "Lab Notebook" light system still governs Calendar, Calorie Log, Add Food, Calorie Goal and Profile, while Auth, Onboarding, Home, Split Editor and Split History were later restyled against dark "Apple Fitness" mockups with their own fixed palettes (`ApplePalette`, `DarkMockupPalette`) and the Inter typeface. `PRODUCT.md` documents this split as known technical debt.

---

## 🗺️ Roadmap

- **Phase 3 — Reminders**: Firebase Cloud Messaging nudges for check-ins and meals.
- **Phase 4 — Social**: friends, shared streaks, lightweight chat.
- Unify the design system back to one coherent look (resolve the Material-light / Apple-dark split).
- Better nutrition coverage for home-cooked / regional dishes (dedicated dataset or commercial API).
- User-tunable macro split.

---

## 📄 License

No `LICENSE` file is currently included in this repository — all rights reserved by the author. Add one to make reuse terms explicit.

---

<div align="center">

`⚡ built with flutter + firebase`

</div>
