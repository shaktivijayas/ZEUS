# ZEUS — Phase 1 Design: Foundation + Splits + Check-in Streak

## Context

ZEUS is a gym companion app being built in four phases:

1. **Foundation + Split/Workout tracking + Check-in streak** (this spec)
2. Calorie tracking
3. Reminders
4. Social / friends / chat

Each phase gets its own design spec, plan, and implementation cycle. This document covers Phase 1 only.

## Platform & Distribution

- **Android only.** Distributed as a shareable APK built with `flutter build apk` — no Play Store.
- **Framework:** Flutter (Dart). Chosen for familiarity (existing `zone` project) and fast APK builds.
- **State management:** Riverpod.
- **Backend:** Firebase — Firebase Auth (email/password) and Cloud Firestore. Firebase Cloud Messaging is reserved for Phase 3 (reminders) but not used in Phase 1.
- **Offline behavior:** Firestore's local cache means check-ins and workout logs work while offline at the gym; writes sync once connectivity returns. UI updates optimistically.

## Data Model (Firestore)

```
users/{uid}
  - name, email, createdAt
  - currentStreak: int
  - longestStreak: int
  - freezesRemaining: int        (resets monthly, default 2/month)
  - freezesResetDate: timestamp
  - onboarded: bool              (false until first split day is created)

users/{uid}/splitDays/{dayId}    // one doc per day of week, Mon–Sun
  - label: string                (e.g. "Chest & Shoulders")
  - order: int                   (for reordering)
  - exercises: [
      { name, targetSets, targetReps, targetWeight, order }
    ]

users/{uid}/checkIns/{date}      // doc ID = "YYYY-MM-DD" (date is the key — enforces idempotency)
  - type: "checked_in" | "rest_day" | "freeze_used" | "missed"
  - timestamp: datetime          (when the doc was written / check-in tapped)
  - workoutLogId: string | null  // set once a workoutLogs draft/completed doc exists for this date

users/{uid}/workoutLogs/{logId}
  - date, splitDayId
  - status: "draft" | "completed"
  - exercises: [
      { name, targetSets, targetReps, targetWeight, actualSets, actualReps, actualWeight, status: "done" | "skipped", notes }
    ]
  - completedAt: datetime | null
```

## Check-in & Streak Logic

### Check-in vs. workout completion (decoupled)

- Tapping **"Check In"** immediately writes `checkIns/{today}` as `type: checked_in` and grants streak credit right then — independent of whether any exercises are logged afterward.
- The day's split checklist is shown after check-in. `workoutLogs` draft is created only once the user checks off their **first** exercise (`status: draft`); every subsequent edit (checkbox, weight, reps, notes) autosaves to that draft immediately, so backing out mid-session loses nothing.
- **Finish**: always enabled.
  - If no exercises were ever touched (no draft exists), Finish (or simply backing out) returns to Home with no `workoutLogs` doc created — nothing to finalize, and streak credit was already granted at check-in.
  - If at least one exercise was touched, Finish flips the draft's `status` to `completed`; any untouched exercises are recorded `status: skipped`.

### Idempotency

`checkIns/{date}` uses the calendar date string as the document ID itself, not an auto-generated ID. A second "Check In" tap the same day overwrites/no-ops the same doc. `currentStreak` is always derived from the sequence of `checkIns` docs, never incremented directly by a button tap, so double-tapping cannot double-count.

### Multi-day gap algorithm (runs on app open)

Given `lastActivityDate` (the most recent date with any `checkIns` doc) and `today`:

0. **Before walking the gap**, check `freezesResetDate`; if it has passed, reset `freezesRemaining` to 2 and advance `freezesResetDate` forward by one month. This must happen first — otherwise a stale, already-due-for-reset low freeze count could wrongly cause a `missed` day during the walk below when a reset should have applied instead.
1. Walk forward date-by-date from the day after `lastActivityDate` through yesterday, **oldest first**.
2. For each date in the range: **first check whether a `checkIns` doc already exists for that date** (e.g. a rest day pre-marked in advance via the calendar). If a doc already exists, skip it entirely — do not touch it, do not consume a freeze.
3. If no doc exists for that date:
   - If `freezesRemaining > 0`: write `type: freeze_used`, decrement `freezesRemaining`, continue to the next date.
   - If `freezesRemaining == 0`: write `type: missed`, set `currentStreak = 0`. Continue walking the **remaining** dates in the range and write `type: missed` for each of those too (this only affects calendar rendering — `currentStreak` is already locked at 0 and freeze budget is left untouched for future gaps).
4. Today is left open: if the user checks in today, `currentStreak` becomes 1 (if the streak just broke) or increments normally (if the whole gap was bridged by freezes/rest days).

This algorithm is a pure function of `(lastActivityDate, today, freezesRemaining, existing checkIns docs) → (writes[], newStreak, newFreezesRemaining)` and is fully unit-testable without a live Firestore instance.

## Screens

- **Auth** — sign up / log in (Firebase Auth).
- **Onboarding** — shown immediately after first sign-up (checked via `users/{uid}.onboarded == false`); routes the user straight into the Split Editor to build their first split before they ever see Home. Sets `onboarded: true` once at least one split day is saved.
- **Home** — today's date, streak counter, "Check In" button; after check-in, shows today's checklist. If no split day is configured for today (edge case post-onboarding, e.g. all days later deleted), shows a prompt to go set one up — a fallback safety net, not the primary onboarding path.
- **Split Editor** — create/edit/reorder weekly split days and their exercises.
- **Calendar** — month grid showing `checked_in` / `rest_day` / `freeze_used` / `missed` per day; tapping a future or today date lets the user mark it as a planned rest day.
- **Split-Day History** — for a given split day (e.g. "Chest & Shoulders"), a reverse-chronological list of past completed `workoutLogs` to track weight/rep progression.
- **Profile / Settings** — shows `longestStreak`, `freezesRemaining` (with reset date), log out.

## Error Handling

- No split configured for today → Home shows a prompt to set one up instead of an empty checklist (see Home, above).
- Offline check-in → written to local Firestore cache immediately, UI updates optimistically, syncs when back online.
- Auth/network failure on launch → last-known cached state shown read-only with a banner, rather than blocking the app.

## Testing Plan

- **Unit tests** for the streak/gap-walk algorithm: consecutive-day math, freeze consumption, rest-day bridging, rest-day-vs-gap-walk interaction (pre-existing docs are skipped, never overwritten), backfilled `missed` days beyond freeze exhaustion, idempotent double check-in, monthly freeze reset (including the ordering case: a stale/due-for-reset `freezesResetDate` must reset `freezesRemaining` before the gap-walk runs, not after).
- **Widget tests** for the check-in flow (including draft autosave / resume-after-backing-out) and the Split Editor.
- **Firestore security rules tests** via the Firebase emulator suite: a user can read/write only under `users/{uid}/*` where `uid == request.auth.uid`; all cross-user access attempts are denied.
- **Manual verification** on a real Android device/emulator using the actual built APK before calling Phase 1 done.

## Known Tradeoffs (accepted, no action needed)

- Day-of-week / "today" detection uses device local time. Traveling across time zones near midnight could misattribute a check-in to the wrong day. Accepted as-is.
