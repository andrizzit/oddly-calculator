# Oddly: serious math, tiny nonsense

Oddly is the recommended working brand: short, friendly, and about curiosity rather than incompetence. Alternatives considered were Pocket Nonsense (too long) and Tally Ho (too close to a familiar expression and less distinctive). App Store name availability and trademark clearance still need release review; this is a creative recommendation, not a clearance claim.

The character is a little geometric creature with eyes, not a chat assistant. It is pleased to be here. It never judges someone's ability, spending, body, work, or habits. Its world contains overly organized bytes, invisible ribbons, stationery cupboards, and tiny ducks. Jokes target the fictional machinery of arithmetic.

## Market observations

Research checked on 11 September 2026 using first-party sources:

- [PCalc](https://pcalc.com/ios/index.html) competes on professional depth, custom layouts, themes, paper tape, conversions and RPN. Its [release history](https://pcalc.com/ios/history.html) also shows playful About experiences and support for disabling animations. Our interpretation: technical trust and delight can coexist, but a copied PCalc feature list would not establish a distinct everyday identity.
- [Soulver](https://documentation.soulver.app/) emphasizes native interfaces, natural language, personalization and avoiding bloat. Its [getting started guide](https://documentation.soulver.app/documentation/getting-started) demonstrates numbers in an editable notepad with immediate answers. Our interpretation: Oddly should have a deliberate keypad-first workflow and resist turning into a second notepad calculator.

These are product-positioning observations, not market-size or demand claims. Pricing is deliberately omitted because it varies by region and changes. Broader competitive evidence belongs in the control room's market report.

## Agreed disagreement

The architect challenged three personality modes: more settings could overcomplicate version one, and “Unhinged” could imply interruption. The compromise preserves the requested spectrum, with one shared layout; copy, frequency, and brief optional mascot decoration can change. It never changes calculation logic, keyboard placement, result formatting, or accessibility behavior.

| Mode | Ordinary result companion | New collectible reveals | Voice |
| --- | --- | --- | --- |
| Calm | None | Paused | Quiet, plain |
| Playful, default | Every fourth successful equals | At the matching result, once | Warm dry wit |
| Unhinged | Every second successful equals | At the matching result, once | More absurd, equally unobtrusive |

The funny designer and architect also rejected sexual calculator spellings, pop-culture quotes, intrusive pranks, streaks, pressure to return, advertising hooks, and joke-based error messages. A calculator should never appear uncertain about an answer for comedic effect.

## Interaction contract

1. Evaluate arithmetic first. Call `PersonalityEngine.reaction` only after a successful equals operation, including the first explicitly confirmed numeric entry if supported by the engine.
2. The reaction is a small optional companion below the real answer. It does not overlay a key, delay input, steal focus, present a modal, or change copied/shared calculation text.
3. Pass the previous successful result to suppress consecutive repeated answers. Save each discovered egg ID locally; subsequent matches never repeat its discovery reveal. Pass a successful-calculation count to apply ordinary-copy rate limits.
4. At most one reaction is returned. There is no time-based scheduler, timer, daily challenge, notification, network request, analytics, audio, or random reward mechanic.
5. Calm returns no reactions and pauses new discoveries. Switching personality never deletes discoveries. A collection screen can show collected items and optional hints for undiscovered items at the user's request.
6. Do not post a VoiceOver announcement for companion copy. Let it remain independently readable through ordinary accessibility navigation. Announce the real answer as appropriate; accessible button labels remain literal.
7. Use restrained feedback for new discoveries only. Respect Reduce Motion and haptics preferences. Motion is optional decoration, never needed to understand the result or unlock an item.
8. Input errors use direct corrective language supplied by the calculator, not a joke. There is no humor at the user's expense.

## Discoveries

All eight are deterministic, local, independent of date or timezone, and match the exact positive Decimal result after equals. Any expression yielding that number works. Each hint includes a direct route, so discovery does not depend on cultural knowledge. The 3.14 trigger is a short approximation of pi, not a claim that pi equals 3.14. The 1729 title refers to the integer's representation as the sum of two positive cubes in two different ways.

| Stable ID | Title | Exact result | Hint expression |
| --- | --- | ---: | --- |
| `cosmic-receipt` | Cosmic Receipt | 42 | `6 × 7` |
| `tiny-pie` | Tiny Pie | 3.14 | `3 + 0.14` |
| `century-club` | Century Club | 100 | `25 × 4` |
| `byte-sized` | Byte Sized | 256 | `16 × 16` |
| `lost-and-found` | Lost & Found | 404 | `400 + 4` |
| `paper-cranes` | Paper Cranes | 1000 | `250 × 4` |
| `taxi-for-cubes` | Taxi for Cubes | 1729 | `1728 + 1` |
| `mirror-mirror` | Mirror, Mirror | 12321 | `12320 + 1` |

The code catalogue is the source of truth for shipped copy and SF Symbols names. Stable IDs must not change after release. The engine uses an explicit UTF-8 fold for ordinary copy selection rather than Swift's randomized Hasher, so the same input produces the same line across runs.

## QA handoff

Verify Calm silence; exact positive matches and near-miss decimals; one-time persistence; repeat-result suppression; independent triggers; predictable copy cadence; every hint solves to its trigger; no input blocking; VoiceOver focus stays put; Reduce Motion respected; and no joke contaminates the result, copied text, error text, or history value. Test at large Dynamic Type and with the longest Unhinged line. A locked collectible needs a readable title or “Undiscovered” label and an explicit hint affordance, not color alone.

## A tiny victory

New discoveries earn a brief native-vector celebration confined to the mascot: a party hat and pastel sparks in Playful; a ceremonial moustache and three miniature colleagues join in Unhinged. The effect ends after about 1.2 seconds. It never receives touches, changes layout, covers numbers, or appears for a repeated discovery. Calm and Reduce Motion disable it. Returning to a screen does not replay an old celebration.
