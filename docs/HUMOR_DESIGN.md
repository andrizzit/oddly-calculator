# Humor and discoveries

Oddly's humor lives in the small companion beside the calculator. Jokes can make the fictional machinery of arithmetic ridiculous; the answer must remain trustworthy.

## Voice

Write short, original, family-friendly lines. Playful is warm and dry; Unhinged adds tiny ducks, ceremonial moustaches, and other harmless absurdity. Never judge the user's ability, spending, body, work, or habits. Avoid sexual calculator spellings, borrowed catchphrases, pranks, and jokes that suggest the arithmetic is unreliable. Errors use direct, helpful language.

## Behavior to preserve

| Mode | Ordinary jokes | New discoveries |
| --- | --- | --- |
| Calm | None | Paused |
| Playful, default | Eligible every fourth successful equals | Reveal once on a matching result |
| Unhinged | Eligible every second successful equals | Reveal once on a matching result |

- Evaluate arithmetic first. The view model calls `PersonalityEngine.reaction` only when equals produces a successful calculation record. It persists the calculation count and discovered IDs locally.
- Return at most one reaction. A new discovery takes priority over ordinary copy. Consecutive equal results suppress both. A previously discovered result can still receive ordinary copy at the configured cadence.
- Keep jokes separate from answers, copied text, history values, and errors. Never delay input, move keys, cover numbers, steal focus, or open a modal.
- Changing personality preserves the collection. Discoveries remain collected until the user resets them. Keep triggers deterministic and independent of date, timezone, network access, and randomness. Do not add streaks, notifications, analytics, or pressure to return.
- Companion text stays readable through normal VoiceOver navigation; do not announce it automatically. Accessible control labels remain literal. Respect large Dynamic Type and haptics preferences.
- Discovery celebrations stay confined to the mascot, ignore touches, and end after about 1.2 seconds. Calm and Reduce Motion disable them. Returning to the screen must not replay an old celebration. Do not add continuous animation or persistent timers.

## Add a joke or discovery

[Personality.swift](../Sources/CalculatorCore/Personality.swift) is the source of truth for copy, modes, symbols, and triggers.

For ordinary jokes, edit `playfulLines` or `unhingedLines`. Keep the deterministic UTF-8 selection logic; Swift's randomized `Hasher` would change selections between runs.

For a discovery:

1. Add an `EasterEgg` to `catalogue` with a unique, permanent ID, short title, supported SF Symbol, both messages, and a clear hint. Never rename a released ID: saved collections depend on it.
2. Add its exact `Decimal` trigger at the corresponding index in `matchingEgg`'s values array. Avoid binary floating-point approximations and duplicate triggers.
3. Include a working expression in the hint, so discovery needs no cultural knowledge. Update the table below, discovery counts in the README and collection UI, and the test fixtures, including the catalogue count assertion.

Current discoveries match exact positive results after equals; any expression yielding that result works. The `3.14` trigger is an approximation of pi.

| Stable ID | Result | Hint expression |
| --- | ---: | --- |
| `cosmic-receipt` | 42 | `6 × 7` |
| `tiny-pie` | 3.14 | `3 + 0.14` |
| `century-club` | 100 | `25 × 4` |
| `byte-sized` | 256 | `16 × 16` |
| `lost-and-found` | 404 | `400 + 4` |
| `paper-cranes` | 1000 | `250 × 4` |
| `taxi-for-cubes` | 1729 | `1728 + 1` |
| `mirror-mirror` | 12321 | `12320 + 1` |

## Checks for changes

Extend `AdversarialPersonalityTests` in [AdversarialTests.swift](../Tests/CalculatorCoreTests/AdversarialTests.swift) for exact triggers, nearby decimals, negative values, Calm silence, saved IDs, repeat suppression, and deterministic cadence. Verify that every hint reaches its trigger.

[OddlyUITests.swift](../OddlyUITests/OddlyUITests.swift) covers discovery persistence, uninterrupted input, stable key positions, and Calm settings. Check new copy at large Dynamic Type and with VoiceOver. Inspect celebrations with Reduce Motion enabled. Locked collectibles need a readable state and an explicit hint affordance, without relying on color alone.
