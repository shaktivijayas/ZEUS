# ZEUS — Phase 2 Design: Calorie Tracking

## Context

ZEUS is a gym companion app being built in four phases:

1. Foundation + Split/Workout tracking + Check-in streak (Phase 1, shipped)
2. **Calorie tracking** (this spec)
3. Reminders
4. Social / friends / chat

Each phase gets its own design spec, plan, and implementation cycle. This document covers Phase 2 only.

Phase 2 is **independent** of Phase 1's check-in/streak system by design: logging food never affects `currentStreak`, and the gap-walk algorithm is untouched. Calorie tracking is its own screen/tab with its own state.

## Platform & Distribution

Unchanged from Phase 1: Android-only Flutter app, distributed as a shareable APK (`flutter build apk`, no Play Store), Riverpod for state management, Firebase Auth + Cloud Firestore for backend, offline-first via Firestore's local cache with optimistic UI updates.

## Data Model (Firestore)

Extends the existing `users/{uid}` document and adds one new subcollection, following the same conventions as Phase 1 (date-string doc IDs for idempotency, embedded arrays for line items rather than sub-subcollections):

```
users/{uid}
  + calorieGoal: int | null                        // null = TDEE calculator never completed
  + macroGoals: { protein, carbs, fat } | null      // grams; derived from calorieGoal
  + tdeeProfile: { weightKg, heightCm, age, sex, activityLevel, goal } | null  // saved inputs, re-editable

users/{uid}/foodLogs/{date}      // doc ID = "YYYY-MM-DD", same idempotent-key pattern as checkIns
  - meals: {
      breakfast: [entry],
      lunch: [entry],
      dinner: [entry],
      snacks: [entry]
    }

entry = {
  name: string,
  calories: number,       // total for this entry, already scaled — not a per-100g figure
  protein: number,         // grams, total for this entry
  carbs: number,            // grams, total for this entry
  fat: number,                // grams, total for this entry
  quantity: number | null,   // grams entered/scaled for openfoodfacts entries; null for manual entries
  unit: string | null,        // "g" for openfoodfacts entries; null for manual entries
  source: "manual" | "openfoodfacts",
  loggedAt: datetime
}
```

`calories`/`protein`/`carbs`/`fat` are always the **total** for the entry, never a per-100g figure — for `openfoodfacts` entries they're computed by scaling the search result's per-100g data by the entered quantity at save time (see Food Search, below); for `manual` entries the user types the totals directly (e.g. "this bowl of dal makhani was 350 kcal, 18g protein"), with no quantity/scaling step, since there's no per-100g baseline to scale from.

Entries are **snapshotted** at save time — full nutrition data is embedded directly in the entry, not referenced from a shared catalog. This means editing or re-searching a food later never retroactively changes a historical day's log. There is no personal "food catalog" subsystem in Phase 2; a lightweight "recently logged" quick-add is computed client-side from the user's own last N entries across recent `foodLogs` docs, rather than persisted as a separate collection.

## Goal Calculation (TDEE)

Computed client-side via the Mifflin-St Jeor formula — no external API, no network dependency:

- `BMR = 10×weightKg + 6.25×heightCm − 5×age + (5 if male, −161 if female)`
- `TDEE = BMR × activityMultiplier`
  - sedentary: 1.2, light: 1.375, moderate: 1.55, active: 1.725, very active: 1.9
- `calorieGoal = TDEE` adjusted by stated goal:
  - lose weight: `TDEE − 500`
  - maintain: `TDEE`
  - gain weight: `TDEE + 300`
- `macroGoals` derived from `calorieGoal` via a fixed split — protein 30% / carbs 40% / fat 30% of calories, converted to grams at 4/4/9 kcal per gram respectively. This split is a reasonable default for a gym-focused app and is not user-tunable in Phase 2.

Inputs (`weightKg`, `heightCm`, `age`, `sex`, `activityLevel`, `goal`) are saved to `tdeeProfile` so the calculator can be re-opened and adjusted later; `calorieGoal`/`macroGoals` are recomputed and overwritten on save.

## Food Search (Open Food Facts)

A `FoodSearchRepository` wraps Open Food Facts' free `/api/v2/search` endpoint (no API key required):

- Query is debounced (~400ms, minimum 2 characters) before firing, to avoid excessive requests while typing.
- Raw results are normalized into `FoodSearchResult { name, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g }`. Results missing a usable calorie/macro figure are filtered out rather than shown with broken data — Open Food Facts is crowdsourced and coverage is inconsistent, especially for home-cooked/loose dishes vs. packaged products.
- After picking a result, the user enters a quantity in grams; calories and macros are scaled from the per-100g figures (`value × quantity / 100`) to produce the entry's total `calories`/`protein`/`carbs`/`fat` before saving. This produces the same entry shape as manual entry — search and manual entry converge on one save path (both end up as an entry with total, already-scaled nutrition values), they just populate the form differently, and only the search path populates `quantity`/`unit`.
- Network failure or an unreachable API surfaces an inline error in the search tab with a "switch to manual entry" affordance. It never blocks the Add Food screen — consistent with Phase 1's offline-tolerant posture.

## Screens

- **Calorie Log** (`/calories`, optionally `/calories/:date`) — day view. Meals grouped (Breakfast/Lunch/Dinner/Snacks) with per-meal subtotals and a daily total shown against `calorieGoal` (e.g. "1450 / 2200 kcal"). Prev/next day navigation, mirroring the Calendar screen's reviewable-history pattern. If `calorieGoal` is null, shows totals with no progress bar and a "Set your goal" prompt linking to Calorie Goal Setup, instead of a blocking or broken 0/0 display.
- **Add Food** (`/calories/:date/add/:mealType`) — two entry paths converging on one save action: **Search** (debounced Open Food Facts query, tap a result to prefill per-100g data, then enter a quantity in grams to scale to totals) and **Manual** (type name and total calories, optional total protein/carbs/fat, directly — no quantity step). Reachable via an add button per meal section on the Calorie Log screen.
- **Calorie Goal Setup** (`/profile/calorie-goal`) — the TDEE calculator form (weight, height, age, sex, activity level, goal). Pre-fills from `tdeeProfile` if present. Reachable from the existing Profile screen. Writes `calorieGoal`, `macroGoals`, and `tdeeProfile` on save.

Navigation entry point: a new icon on Home's AppBar leading to `/calories`, following the same pattern already used for Calendar and Split Editor.

## Error Handling

- No `calorieGoal` set → Calorie Log shows totals with no progress bar and a prompt to Calorie Goal Setup, not a blocking state (see Screens, above).
- Offline food logging → written to Firestore's local cache immediately, UI updates optimistically, syncs when back online — same pattern as Phase 1 check-ins. Manual entry works fully offline; search requires connectivity.
- Open Food Facts unreachable or returns malformed data → inline error in the search tab with a manual-entry fallback, never a crash or blocking dialog.

## Testing Plan

- **Unit tests** for the TDEE/macro-goal calculation: BMR formula correctness, each activity multiplier, each goal adjustment (lose/maintain/gain), macro-gram conversion from calories. Pure function, no Firestore dependency — same style as Phase 1's gap-walk tests.
- **Unit tests** for `FoodSearchRepository`'s per-100g → per-quantity scaling math, and for filtering out results with missing/malformed nutriment data.
- **Widget tests** for: Calorie Log (meal grouping, subtotals, goal progress display, dormant-goal state), Add Food (search tab scales per-100g by quantity into entry totals, manual tab saves typed totals directly with `quantity`/`unit` left null, both produce a valid entry), Calorie Goal Setup form (pre-fill from existing `tdeeProfile`, save writes all three fields).
- **Firestore security rules tests** (emulator suite): extend Phase 1's existing rules tests to cover `foodLogs/{date}` under the same `users/{uid}/*` ownership rule — no new rule shape, just added coverage.
- **Manual verification** on a real Android device/emulator using the built APK, following the same checklist-style approach as Phase 1's Task 16, before calling Phase 2 done.

## Known Tradeoffs (accepted, no action needed)

- Open Food Facts has inconsistent coverage of home-cooked/loose dishes (e.g. "dal makhani") since it's a crowdsourced, largely packaged-product-centric database. Manual entry is the fallback for anything not found. A dedicated Indian-cuisine dataset or a commercial API (Nutritionix/Edamam) could improve this later, but adds an API key/rate-limit dependency Phase 2 avoids.
- Macro split (30/40/30) is a fixed default, not user-tunable in Phase 2. Revisit if user feedback calls for it.
- No personal food catalog/reusable-foods subsystem in Phase 2 — every manual entry and every search result is saved as a one-off snapshot. The client-side "recently logged" quick-add covers the common case (re-logging something eaten in the last few days) without the added complexity of a catalog with its own edit/reference semantics.
