# Product

## Register

product

## Platform

android — with an intentional exception: the visual skin is Apple Fitness/iOS HIG, not Material 3. Screens use Cupertino-shaped icons and controls, a system-gray/dark palette, and an SF-Pro-style type stand-in (Inter, since real SF Pro can't be bundled for Android) by deliberate choice, not by native-slop accident. Android's *system* guarantees still apply regardless of visual skin — predictive Back gesture, edge-to-edge window insets, 48×48dp touch targets — see DESIGN.md §7.

## Users

The app's creator plus a small group of friends/family who train and eat with intention. They open it daily, in the middle of a workout or right after a meal — not sitting down for a "session." The job to be done each time is narrow and specific: log a check-in, complete today's split, or log a meal, then get back to what they were doing.

## Product Purpose

ZEUS helps a small group of self-directed people stay consistent with training and nutrition through structured split-day workouts, daily check-in streaks, and calorie/macro logging. It exists to remove friction from the daily habit loop, not to coach or motivate through pressure. Success is habitual daily use and an honest, low-friction record — not engagement metrics or gamified hooks.

## Positioning

ZEUS is a calm, personal record-keeper for training and eating — not a coach shouting at you, just an honest daily log that stays out of your way.

## Brand Personality

Calm and focused, like a well-organized notebook — now expressed literally as Apple Fitness's own dark visual language, not just "inspired by" it: pitch-black screens, `#1C1C1E` card surfaces, the three real Fitness ring colors (Exercise Green `#30D158`, Move Red `#FA114F`, Stand Cyan `#00D4FF`) held in reserve for accents, and restrained data presentation — no hype, numbers stated plainly and trusted to speak for themselves.

## Anti-references

Three things to avoid, explicitly:
- **Cheap neon fitness-app cliché**: this is *not* license for gradients, oversaturated non-system colors, gamified badges, or streak-shaming — the target is Apple's exact restrained system palette (§ DESIGN.md Colors), not a louder one. If a color used doesn't trace back to a named Apple Fitness system value, it's off-brand.
- **Generic default Material left unconverted**: any screen still riding a single Material 3 seed color with no layout/typography/component work applied is in the old failure state, whether or not the app has moved on elsewhere.
- **A split brand**: some screens carrying the dark Apple Fitness system, others still on the light Material "Lab Notebook" system, is now the patchwork risk to watch for (see Design Principles below) — screens should be migrated deliberately, not left half-converted.

## Design Principles

Quiet by default — data and structure lead; decoration never competes with them.

One clear focus per screen — no competing calls to action fighting for attention.

Progress shown honestly, not hyped — streaks and calories are information to reflect on, not a game score to chase.

No fabricated data behind a real-looking metric — when a visual design calls for a category or a ring ZEUS doesn't actually track (e.g. Apple Fitness's Stand ring, or Mindfulness/Walking session types), map it to the closest real signal ZEUS has, or drop it, rather than rendering something that looks like a tracked stat but isn't backed by anything (see the Calendar screen's Rings/Sessions mapping in DESIGN.md).

One coherent notebook, not a patchwork — every screen, old and new, should read as the same calm system, not eight different default-Material screens bolted together.

Never let visual polish slow the daily habit loop — the fastest path to logging a check-in, a set, or a meal always wins over decoration.

## Accessibility & Inclusion

Standard baseline: WCAG AA contrast (≥4.5:1 body text, ≥3:1 large text), text that respects the system font-scale setting, and no motion that could trigger discomfort — every animation gets a reduced-motion-safe alternative. No additional personal accessibility requirement specified.
