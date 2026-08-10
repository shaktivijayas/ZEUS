<!-- SEED: this project had no CSS/Tailwind tokens to scan (Flutter/Material3 native app, only a single theme seed color existed). Tokens below are a fresh, considered starting system rather than an extraction of prior work. Re-run /impeccable document once the system below has shipped across a few screens, to capture any drift as real implementation settles in. -->

---
name: ZEUS
description: A calm, personal record-keeper for training and eating.
colors:
  forest-green: "#2E7D32"
  ink: "#1A1D1B"
  muted-ink: "#55605A"
  background: "#F6F8F6"
  surface: "#FFFFFF"
  divider: "#E3E7E3"
  error: "#B3261E"
typography:
  display:
    fontFamily: "Roboto, sans-serif"
    fontSize: "28sp"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "normal"
  headline:
    fontFamily: "Roboto, sans-serif"
    fontSize: "22sp"
    fontWeight: 600
    lineHeight: 1.2
  title:
    fontFamily: "Roboto, sans-serif"
    fontSize: "17sp"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Roboto, sans-serif"
    fontSize: "15sp"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "Roboto, sans-serif"
    fontSize: "13sp"
    fontWeight: 500
    letterSpacing: "0.02em"
rounded:
  sm: "8px"
  md: "12px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.forest-green}"
    textColor: "{colors.surface}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  button-primary-pressed:
    backgroundColor: "#26692A"
    textColor: "{colors.surface}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  chip-selected:
    backgroundColor: "{colors.forest-green}"
    textColor: "{colors.surface}"
    rounded: "{rounded.sm}"
  chip-unselected:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.muted-ink}"
    rounded: "{rounded.sm}"
---

# Design System: ZEUS

## 1. Overview

**Creative North Star: "The Lab Notebook"**

ZEUS is the calm, honest logbook for someone who trains and eats with intention — not a coach shouting at you, not a game keeping score, just a well-organized notebook that's always exactly where you left it. Every screen exists to get one number or one entry logged and get out of the way: a check-in, a completed set, a meal. The visual system stays quiet on purpose, so the only thing that stands out on any screen is the one piece of data that screen exists to show.

This system explicitly rejects the loud fitness-app playbook — neon gradients, aggressive red/orange "burn calories" urgency, gamified badges, streak-shaming, hero-metric dashboards screaming a number at you — and it equally rejects the unstyled-Material default the app currently ships with (one seed color, stock widgets, no real typographic or spatial system). Both are treated as failure states.

**Key Characteristics:**
- One accent color, used sparingly and only for identity + primary action, never decoration
- Flat, tonal surfaces — depth comes from a single layer of surface-on-background, not shadows
- One typeface family throughout, carrying hierarchy through weight and size alone
- Numbers are stated plainly and left to speak for themselves — no celebratory animation, no color-coded "good/bad" judgment on a calorie count
- Every screen has exactly one thing it's asking you to notice or do

## 2. Colors

A restrained palette: near-white and near-black neutrals do essentially all the work, with one green accent held in reserve for the moments that actually need it.

### Primary
- **Deep Forest Green** (`#2E7D32`): The single accent. Used only for the primary action on a screen (Save, Set goal) and the one number a screen most wants you to notice (e.g. the calorie total once a goal exists). Never used as a background fill, decoration, or "positive status" color — see the One Voice Rule below.

### Neutral
- **Ink** (`#1A1D1B`): Primary text. Near-black, not pure black — softer under long reading, still comfortably ≥4.5:1 against Background and Surface.
- **Muted Ink** (`#55605A`): Secondary text only — timestamps, captions, helper text. Checked to stay ≥4.5:1 against Background; if a future value drifts lighter than this for "elegance," that's a regression, not a style choice.
- **Background** (`#F6F8F6`): App background. A near-white with the faintest lean toward the accent's own hue — not a warm cream, not stark white.
- **Surface** (`#FFFFFF`): Cards, list rows, sheets, and fields sit on pure white against the slightly darker Background, which is the system's only depth cue.
- **Divider** (`#E3E7E3`): Hairline separators between list rows and sections. Never used as a decorative border.

### Semantic
- **Error** (`#B3261E`): Validation errors and destructive confirmations only (e.g. a save failure, an invalid amount). A muted brick red, not a saturated alert red — errors should read as "something needs attention," not alarm.

### Material ColorScheme Mapping
This system is implemented as Flutter `ColorScheme` role tokens, not raw hex applied ad hoc — roles resolve contrast correctly; raw hex doesn't. Forest Green → `primary`; white → `onPrimary`; Background → `surface`/scaffold background (the base tone everything sits on); Surface → `surfaceContainerLowest` (the elevated white tone cards/fields sit on, per the Elevation section); Ink → `onSurface`; Muted Ink → `onSurfaceVariant`; Divider → `outline`/`outlineVariant`; Error → `error`; white → `onError`.

### Named Rules
**The One Voice Rule.** Deep Forest Green appears on ≤10% of any given screen's surface area. If more than one element on a screen is fighting for attention in green, the layout is wrong, not the rule.

**No Second Green Rule.** There is no separate "success" or "goal met" color. Progress is communicated through the number itself and its position relative to the goal, in Ink — never through a color swap, checkmark celebration, or badge. This is the direct visual expression of "progress shown honestly, not hyped."

**The Dark-Is-Not-Optional Rule.** This system ships a dark `ColorScheme` using the same role mapping above (surfaces invert, Forest Green lightens to hold contrast on dark backgrounds), generated deliberately, not a quick `Brightness.dark` alpha-invert. `lib/core/theme/app_theme.dart` currently defines only `AppTheme.light` — closing that gap is part of implementing this system, not a follow-up task.

## 3. Typography

**Body Font:** Roboto (system default on Android; no new font dependency)
**Display/Headline/Title/Label:** Roboto, carried through weight and size alone — no second family.

**Character:** One humanist sans doing every job in the app, the way Apple Health leans on San Francisco for everything. Hierarchy is entirely weight- and size-driven, which is what keeps the app feeling like one coherent notebook rather than a set of differently-branded screens. Numeric displays (calorie totals, macro grams, streak counts) use tabular (monospaced) figures so digits align when they change.

### Hierarchy
- **Display** (600, 28sp, 1.15 line-height): The single most important number on a screen — a calorie total against goal, a streak count. Used at most once per screen.
- **Headline** (600, 22sp, 1.2): Screen titles (AppBar titles).
- **Title** (600, 17sp, 1.3): Section headers within a screen (a meal-type label like "Breakfast"), card/list-row primary text.
- **Body** (400, 15sp, 1.4): Form field values, list-row secondary text, body copy generally. Cap any prose block's line length so it never runs edge-to-edge on a wide device.
- **Label** (500, 13sp, 0.02em tracking): Chip labels, field captions, timestamps, button text.

### Named Rules
**The One Family Rule.** If a screen needs a second typeface to feel "designed," the hierarchy is under-specified, not the font choice. Solve it with weight and size first.

## 4. Elevation

Flat by default, tonal instead of shadowed — the Background/Surface contrast (`#F6F8F6` under `#FFFFFF`) is the only depth cue most screens need. This mirrors Apple Health's layered-but-flat sheets rather than Material's default drop-shadow cards.

### Shadow Vocabulary
- **overlay** (`box-shadow: 0 8px 24px rgba(26,29,27,0.12)`): Reserved for transient overlays only — bottom sheets, dialogs, menus. Never applied to a resting card or list row.

### Named Rules
**The Flat-At-Rest Rule.** Nothing that stays on screen gets a shadow. Shadows exist only under things that are temporarily floating above the content and will be dismissed.

## 5. Components

### Buttons
- **Shape:** 8px corner radius — soft, not sharp, not pill-shaped.
- **Primary:** Forest Green background (`#2E7D32`), white text, 12px/24px padding. Pressed state darkens to `#26692A`. This is the only place a filled green button appears — one primary action per screen.
- **Secondary / Text:** No fill, Ink text, no border. Used for anything that isn't the screen's single primary action (e.g. "Switch to manual entry").
- **Disabled (in-flight save):** 40% opacity, no pointer feedback — used while a save is genuinely in progress, per the double-submit guard already in AddFoodScreen.

### Chips (Sex / Activity / Goal / meal-type selection)
- **Unselected:** White surface, Muted Ink text, 1px Divider-colored border, 8px radius.
- **Selected:** Forest Green fill, white text, no border. Selection state is the only place outside the primary button where the accent fills a whole shape — keep it to single-selection chip rows, never a whole screen of filled chips at once.

### Cards / List Rows (food entries, meal groups)
- **Corner Style:** 12px radius on card-like containers; plain hairline-divided rows for simple lists (the food-entry-under-meal-header rows) rather than nesting a card per entry — nested cards are a named anti-pattern for this system.
- **Background:** Surface (`#FFFFFF`) on Background.
- **Shadow Strategy:** None at rest (see Elevation).
- **Border:** None; separation comes from the Background/Surface tone shift, or a single Divider hairline between rows in a flat list.
- **Internal Padding:** `md` (16px) minimum on any tappable row.

### Inputs / Fields (weight, height, age, food name, calories, quantity)
- **Style:** Underline or outlined per Material3 default, Divider-colored border at rest, Forest Green border on focus. No fill.
- **Focus:** Border shifts to Forest Green; no glow, no shadow.
- **Error:** Error red (`#B3261E`) border and helper text, replacing the silent no-op behavior the current AddFoodScreen/CalorieGoalScreen forms have — every invalid input state must be visible in this color, not just logically handled.

### Navigation (AppBar, day-navigation controls)
- **Style:** Headline-weight title, Ink on Surface, flat (no shadow, hairline Divider at the bottom edge if needed for separation). Back affordance always available via the system default — never occupied by a feature control (the day-navigation chevrons belong in `actions`, not `leading`).

## 6. Do's and Don'ts

### Do:
- **Do** hold Deep Forest Green to ≤10% of any screen's surface (the One Voice Rule).
- **Do** use tonal Background/Surface contrast instead of shadows for anything that stays on screen.
- **Do** carry every visual hierarchy decision through Roboto's weight and size alone, mapped to Material's Display/Headline/Title/Body/Label type-scale roles — never a hand-picked size per screen.
- **Do** show every invalid-input and save-failure state visibly, in Error red with real copy — never a silent no-op.
- **Do** leave `AppBar.leading` free for the system back button; put feature controls in `actions`.
- **Do** verify body text hits ≥4.5:1 contrast against its background before shipping any new screen.
- **Do** implement colors as Material `ColorScheme` role tokens with both a light and a dark scheme — see the Dark-Is-Not-Optional Rule.
- **Do** keep every touch target at least 48×48dp, with 8dp between adjacent targets.
- **Do** use `sp` for all type sizes, never fixed `px`/logical pixels, so the system font-size setting is respected.

### Don't:
- **Don't** use neon gradients or saturated "burn calories" red/orange urgency anywhere in the app.
- **Don't** add gamified badges, streak-shaming copy, or celebratory animations for hitting a goal — progress is stated, not applauded.
- **Don't** build a hero-metric dashboard (big number + small label + gradient accent) — the calorie total is one line in the existing screen flow, not its own spectacle screen.
- **Don't** ship a screen using stock, unstyled Material 3 defaults with no layout or typographic decisions applied — that is the exact state this system replaces.
- **Don't** introduce a second "success" color for goals met or streaks kept (the No Second Green Rule).
- **Don't** nest a card inside a card, or wrap every list row in its own elevated container.
- **Don't** apply raw hex values directly in widgets — resolve through `Theme.of(context).colorScheme` roles so light/dark and contrast stay correct.
- **Don't** port in iOS-shaped controls (Cupertino switches, iOS-style dialogs) — this is an Android-only app; Material 3 components throughout.
