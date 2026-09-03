<!-- SEED: this project had no CSS/Tailwind tokens to scan (Flutter/Material3 native app, only a single theme seed color existed). Tokens below are a fresh, considered starting system rather than an extraction of prior work. Re-run /impeccable document once the system below has shipped across a few screens, to capture any drift as real implementation settles in. -->

---
name: ZEUS
description: A calm, personal record-keeper for training and eating.
colors:
  # Dark Apple Fitness system — current system, see §1-6 below.
  apple-background: "#000000"
  apple-card: "#1C1C1E"
  apple-primary-text: "#FFFFFF"
  apple-secondary-text: "#8E8E93"
  apple-exercise-green: "#30D158"
  apple-move-red: "#FA114F"
  apple-stand-cyan: "#00D4FF"
  apple-chevron: "#3C3C43"
  # Legacy light "Lab Notebook" system — pending migration, see §7.
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

## 0. System Status

ZEUS carries **two** design systems right now, mid-migration:

1. **Dark Apple Fitness system** (§1-6 below) — the current, primary system. Live on: `auth`, `onboarding`, `home`, `split_editor` (list + day detail), `split_history`, `calories` (both the calorie log hero-ring screen and Add Food), `calendar` (Rings/Sessions history view).
2. **Legacy light "Lab Notebook" system** (§7) — Material 3, light theme. Still live on: `profile` (+ calorie goal). Kept documented, not deleted, so it stays internally consistent until deliberately migrated. Treat any *new* screen as Dark Apple Fitness by default; don't add new Lab Notebook screens.

A screen belongs fully to one system or the other — never mix tokens from both on the same screen (see Anti-references in PRODUCT.md, "a split brand").

## 1. Overview — Dark Apple Fitness System

**Creative North Star: "The Real Fitness App"**

ZEUS's primary screens now match Apple Fitness's own dark visual language directly, not an inspired-by approximation: pitch-black backgrounds, `#1C1C1E` card surfaces, and the three real Fitness ring colors (Exercise Green, Move Red, Stand Cyan) held in reserve as accents. The habit-loop philosophy carries over unchanged from the original Lab Notebook system — quiet by default, one focus per screen, progress stated rather than hyped — only the surface language changed, from a light Material notebook to Apple's own dark system.

This system still explicitly rejects: gradients, oversaturated non-system colors, gamified badges, streak-shaming, and hero-metric dashboards. The target is Apple's exact restrained system palette, not a louder "fitness app" palette — every color used must trace back to a named value below.

**Key Characteristics:**
- Pure black background; a single card surface tone (`#1C1C1E`) is the only depth cue, no shadows
- Three reserved ring accents (Exercise Green, Move Red, Stand Cyan), each with one job — never decoration, never used interchangeably
- Inter stands in for SF Pro (real SF Pro can't be bundled for Android); hierarchy carried through weight, size, and slight negative tracking on headers, same as native iOS titles
- Numbers are stated plainly — no celebratory animation, no color-coded "good/bad" judgment
- Cupertino-shaped icons and chevrons throughout — this is a deliberate exception to the Android platform convention of never porting iOS controls (see PRODUCT.md Platform); Android's *system* guarantees (Back gesture, edge-to-edge insets, 48×48dp targets) still apply regardless

## 2. Colors

### Ring Accents (the only accent colors in this system)
- **Exercise Green** (`#30D158`): Active/selected tint — the active bottom-tab icon+label, primary navigation affordances (e.g. the Split Editor back chevron). This is the system's "you are here / this is live" color.
- **Move Red** (`#FA114F`): Alert/attention accent — used sparingly for a number or label that wants to be noticed (e.g. an exercise count on an unconfigured day). Not a decoration; if it's not drawing the eye to something that matters, it's the wrong color.
- **Stand Cyan** (`#00D4FF`): Reserved for a third ring/status context (e.g. a future Stand-equivalent metric); not yet used in a shipped screen — don't reach for it as a generic accent.

### Neutral
- **Pure Background** (`#000000`): Scaffold background for every screen on this system.
- **Card Background** (`#1C1C1E`): The single elevated surface tone — list rows, cards, sheets. No second card tone; depth comes from this one background/card contrast, same Flat-At-Rest philosophy as the legacy system.
- **Primary Text** (`#FFFFFF`): Headers, titles, primary row text.
- **Secondary Text / Muted Labels** (`#8E8E93`, iOS System Gray): Subtext, captions, timestamps — implemented as `ApplePalette.dateGray` in code (`lib/core/theme/apple_fitness_palette.dart`; the field predates this doc section and keeps its name to avoid a repo-wide rename, but its value **is** this token).
- **Chevron / Disclosure** (`#3C3C43` at low opacity — `Color(0x663C3C43)`): Thin, quiet, native-feeling disclosure arrows. Never full-opacity solid gray.

### Legacy-adjacent (kept for continuity, not part of the ring-accent vocabulary)
- `ApplePalette.green` (`#A7FE00`) and `ApplePalette.pink` (`#FF2D55`) remain in code, still driving Home's check-in button, activity ring, and checkboxes. They predate this doc's exact-system-color pass and are visually close cousins of Exercise Green / Move Red rather than duplicates — left as-is to avoid an unrequested Home redesign. Don't use them in new work; use the Ring Accents above instead.

### Named Rules
**The Named-Color Rule.** Every color on a Dark Apple Fitness screen must be one of the tokens above (or a system neutral like pure white/black). If you're reaching for a raw hex that isn't named here, it's off-system.

**No Second Green Rule (carried over).** No separate "success" or "goal met" color — progress is stated in place, not celebrated with a color swap.

## 3. Typography

**Font:** [Inter](https://fonts.google.com/specimen/Inter) via `google_fonts`, standing in for SF Pro — see the code comment on `_appleFont()` in `split_editor_screen.dart` for why (SF Pro can't be licensed/bundled for Android). Not Roboto, not the app-wide `AppTypography` scale — this system deliberately opts out of both.

### Hierarchy
- **Card / Screen Headers** ("Monday", "Split Editor"): Bold (700), tight negative tracking (`letterSpacing: -0.4`) — matches native iOS large-title tightening.
- **Subtext / Descriptions** ("Rest day — tap to configure", "Chest · 4 exercises"): Regular weight (400), `#8E8E93`. Never lighter than Regular (w300 reads as too thin against pure black and was corrected away from).
- **Attention indicators** (an exercise count, a Move-ring-adjacent number): Bold/Semibold (600-700) in Move Red — weight *and* color both carry the emphasis.

### Named Rules
**No Light Body Text.** Body/subtext weight floors at Regular (400) on this system — thinner weights lose legibility against `#000000`.

## 4. Elevation

Flat by default — Background/Card contrast (`#000000` under `#1C1C1E`) is the only depth cue, same Flat-At-Rest philosophy as §8 (legacy system). No shadows on resting cards or list rows.

## 5. Components

### Cards / List Rows (weekday rows, split-day cards)
- **Corner Radius:** 12-14pt (`BorderRadius.circular(14)` on the row's `Material`/`InkWell` pair).
- **Background:** Card (`#1C1C1E`) on Background (`#000000`).
- **Internal Padding:** Generous — `AppSpacing.md` (16px) horizontal, `AppSpacing.md + 5` (21px) vertical minimum on a tappable row; `AppSpacing.md` (16px) between stacked cards so the list breathes rather than reading as a dense table.
- **Trailing affordance:** A `CupertinoIcons.chevron_forward` disclosure chevron in the Chevron token, right-aligned, whenever the row navigates somewhere.

### Bottom Tab Bar (`lib/core/widgets/apple_bottom_bar.dart`, shared across every screen reachable from it)
- **Icons:** Thin-line Cupertino icons only, never filled/blocky Material icons — `CupertinoIcons.gauge` (Summary), `CupertinoIcons.calendar` (Calendar), `CupertinoIcons.square_split_2x2` (Split), `CupertinoIcons.flame` (Calories).
- **Active tint:** Exercise Green (`#30D158`). Inactive: `#8E8E93`.
- **Labels:** 11px, weight 600, centered directly beneath each icon.
- **Surface:** Frosted/blurred (`BackdropFilter`, `tabBarBackground` at 75% alpha), not a flat opaque bar.

### Hero Metric Ring (calorie log)
- A glowing circular progress ring (220pt, 16pt stroke, round cap) replaces a flat "consumed / goal" text line whenever a goal exists — track in `ringTrack` (`#400010`), progress in Move Red, a soft Move Red glow (`BoxShadow`, 35% alpha, 36pt blur) behind the ring.
- Centered inside: the consumed total in the oversized hero number style (44pt, Black/w900, `-1.2` tracking, tabular figures) with a muted `of X,XXX kcal goal` caption beneath.
- No-goal state drops the ring entirely (nothing to show progress against) and shows the same oversized total with a `kcal logged today` caption and an Exercise Green pill CTA to set a goal — never a bare "0" with no context.

### Circular Add Button
- 30pt circle, `divider` (`#2C2C2E`) fill, centered `CupertinoIcons.add` at 16pt in Primary Text — the iOS-style thin-line add affordance, replacing a plain Material `+` `IconButton`. Used at the trailing edge of a meal card's header row.

### Segmented Control (Add Food: Manual / Search)
- A 36pt-tall rounded pill track (`card` fill, 18pt radius) containing two equal segments. The active segment gets a smooth `AnimatedContainer`-driven floating capsule (`#EBEBF0`, near-white, 200ms `easeOutCubic`) behind black text; the inactive segment is transparent with `dateGray` text. Never a plain text-link pair for a binary mode switch on this system.

### History Calendar (Rings / Sessions)
- A single continuous 7-column grid spans a fixed 6-month lookback through the current month — flowing, not a bounded single-month view, but not true unbounded infinite scroll either. A short month label (e.g. "Nov") renders inline above the day number on each month's 1st cell, since the grid's day-of-week alignment carries continuously across month boundaries.
- Top bar: "Cancel" (Exercise Green, pops the screen) — left; the month/year of whatever row is nearest the scroll top — center, live-updating as the user scrolls; a "Rings ⌄ / Sessions ⌄" mode popup (Exercise Green) — right.
- **Rings mode**: three concentric rings per day — Move (outer, Red, mapped to calorie-goal progress), Exercise (middle, Green, mapped to a completed workout that day), Stand (inner, Cyan, mapped to check-in status that day — ZEUS has no literal "stand" metric, so this is the closest honest equivalent). A day with all three at zero renders a ghosted low-opacity gray outline instead of colored arcs.
- **Sessions mode**: tiny glyphs below the day number instead of rings — a green running-figure for a completed workout, a cyan crescent moon for a marked rest day. Deliberately limited to real ZEUS categories; no fabricated Mindfulness/Walking glyphs with no data behind them (see PRODUCT.md's data-honesty note on this screen). A bottom filter bar (translucent `tabBarBackground` capsule, Exercise Green pill for the active filter, `divider` fill for inactive) toggles between All / Workouts / Rest days.
- Today's day number is always a solid Move Red filled circle with white text, in both modes.
- Tapping any day still marks it a rest day if no check-in doc exists yet for that date (pre-existing behavior, carried over unchanged from the legacy calendar — never overwrites an existing doc).

### Grouped Form List (Add Food)
- All fields for one logical form step live inside a single `_FormCard`-style container (`card` fill, 14pt radius) as label/value rows, hairline-divided (`divider` at 60% alpha, inset to align with the row's left padding) — never separate bordered boxes stacked with gaps.
- Each row: label left in Primary Text, the `TextField` itself right-aligned with no border/fill (`InputBorder.none`), both entered text and hint tinted `dateGray` (Secondary Text/Muted Labels token) per this screen's exact placeholder-and-value treatment.

### Navigation (AppBar)
- **Style:** `centerTitle: true` — iOS nav bars always center the title, never left-align it next to the back affordance the way Material does by default. Title text is short and uppercase (e.g. "SPLIT", not "Split Editor") at Home's large-title size (34pt, Bold/w700, `-0.4` tracking) — same scale as Home's "Summary" large title, closer to Apple Fitness's own bold category-header treatment than a standard 17pt inline title. `CupertinoIcons.back` in Exercise Green as the leading affordance (this system's one intentional Cupertino-shaped control exception — see §1's platform note).

## 6. Do's and Don'ts — Dark Apple Fitness System

### Do:
- **Do** keep every color on a Dark Apple Fitness screen traceable to a token in §2 (the Named-Color Rule).
- **Do** use Exercise Green only for "active/selected/here" states; Move Red only for attention/alert states. Don't swap their jobs.
- **Do** keep subtext at Regular weight or heavier — never Light/w300.
- **Do** apply slight negative letter-spacing to bold headers (`-0.4`) for the native-iOS-title feel.
- **Do** keep the bottom tab bar's icon set thin-line/Cupertino-shaped; a filled Material icon here is an immediate regression.
- **Do** honor Android's system guarantees (Back gesture, edge-to-edge insets, 48×48dp touch targets) even though the visual skin is iOS-shaped.

### Don't:
- **Don't** introduce a fourth accent color outside Exercise Green / Move Red / Stand Cyan.
- **Don't** use gradients, glow, or non-system-accurate hex values "for polish" — accuracy to the real Apple Fitness palette is the polish.
- **Don't** mix this system's tokens onto a Legacy-system screen (§7) or vice versa on the same screen.
- **Don't** add a second card surface tone; `#1C1C1E` is the only elevated tone.

---

## 7. Legacy Light System ("Lab Notebook")

Still governs `calendar`, `calories` (log + add food), and `profile` (+ calorie goal) as of this writing. Documented in full below so those screens stay internally consistent until deliberately migrated to the Dark Apple Fitness system — don't use these tokens on a new screen.

### 7.1 Overview

ZEUS's original system: the calm, honest logbook — not a coach shouting at you, not a game keeping score. Every screen exists to get one number or one entry logged and get out of the way. Rejects the loud fitness-app playbook (neon gradients, urgency red/orange, gamified badges) and the unstyled-Material default equally.

**Key Characteristics:**
- One accent color (Forest Green), used sparingly, never decoration
- Flat, tonal surfaces — depth from surface-on-background, not shadows
- One typeface (Roboto) carrying hierarchy through weight and size alone
- Numbers stated plainly, no celebratory color-coding

### 7.2 Colors

**Primary** — **Deep Forest Green** (`#2E7D32`): The single accent. Primary action (Save, Set goal) and the one number a screen most wants noticed. Never a background fill or "positive status" color.

**Neutral:**
- **Ink** (`#1A1D1B`): Primary text.
- **Muted Ink** (`#55605A`): Secondary text only — ≥4.5:1 against Background.
- **Background** (`#F6F8F6`): App background.
- **Surface** (`#FFFFFF`): Cards, rows, sheets, fields.
- **Divider** (`#E3E7E3`): Hairline separators only.

**Semantic** — **Error** (`#B3261E`): Validation errors and destructive confirmations only.

**Material ColorScheme Mapping:** Forest Green → `primary`; white → `onPrimary`; Background → `surface`/scaffold background; Surface → `surfaceContainerLowest`; Ink → `onSurface`; Muted Ink → `onSurfaceVariant`; Divider → `outline`/`outlineVariant`; Error → `error`; white → `onError`.

**Named Rules:**
- **The One Voice Rule.** Forest Green appears on ≤10% of any screen's surface.
- **No Second Green Rule.** No separate "success"/"goal met" color.
- **The Dark-Is-Not-Optional Rule.** This legacy system ships its own dark `ColorScheme` (same role mapping, surfaces inverted) — unrelated to the Dark Apple Fitness system in §1-6, which is a different visual system entirely, not this system's dark mode.

### 7.3 Typography

Roboto throughout, weight/size-driven hierarchy, tabular figures for numeric displays.

- **Display** (600, 28sp, 1.15): The single most important number on a screen.
- **Headline** (600, 22sp, 1.2): Screen titles.
- **Title** (600, 17sp, 1.3): Section headers, card/list-row primary text.
- **Body** (400, 15sp, 1.4): Field values, list-row secondary text.
- **Label** (500, 13sp, 0.02em): Chips, captions, timestamps, buttons.

**The One Family Rule.** If a screen needs a second typeface to feel designed, the hierarchy is under-specified.

### 7.4 Elevation

Flat by default — Background/Surface contrast is the only depth cue. **overlay** shadow (`0 8px 24px rgba(26,29,27,0.12)`) reserved for transient sheets/dialogs/menus only. **The Flat-At-Rest Rule**: nothing that stays on screen gets a shadow.

### 7.5 Components

- **Buttons:** 8px radius. Primary: Forest Green bg, white text, 12px/24px padding, pressed → `#26692A`. Secondary/Text: no fill, Ink text. Disabled (in-flight save): 40% opacity.
- **Chips:** Unselected: white surface, Muted Ink text, 1px Divider border, 8px radius. Selected: Forest Green fill, white text, no border.
- **Cards / List Rows:** 12px radius on cards; hairline-divided plain rows for simple lists (no nested cards). Surface on Background, no shadow at rest, `md` (16px) minimum internal padding.
- **Inputs:** Divider-colored border at rest, Forest Green border on focus, no fill. Error: Error-red border + visible helper text, never a silent no-op.
- **Navigation:** Headline-weight title, Ink on Surface, flat. `AppBar.leading` reserved for system back; feature controls go in `actions`.

### 7.6 Do's and Don'ts

**Do:** hold Forest Green to ≤10% of a screen; use tonal contrast instead of shadows; carry hierarchy through Roboto weight/size via Material type-scale roles; show invalid-input/save-failure states visibly in Error red; leave `AppBar.leading` for system back; verify ≥4.5:1 body contrast; implement colors as `ColorScheme` roles with light+dark; 48×48dp touch targets, 8dp gaps; `sp` units always.

**Don't:** use neon gradients or saturated urgency red/orange; add gamified badges or streak-shaming; build a hero-metric dashboard; ship stock unstyled Material 3; add a second "success" color; nest cards; apply raw hex outside `ColorScheme` roles; port in Cupertino-shaped controls — **this rule is specific to Legacy-system screens**; the Dark Apple Fitness system in §1-6 carries a deliberate, documented exception to it.
