# Oddly market research

Research date: 11 September 2026. Scope: public first-party product pages, documentation, and US App Store listings. This is a product-design study, not a market-size estimate or a hands-on benchmark. Storefront availability, features, and prices can change. Review comments are individual anecdotes, not representative user research.

## What already exists

| Product | Established strength | Implication for Oddly |
| --- | --- | --- |
| [Apple Calculator](https://support.apple.com/guide/iphone/get-started-with-calculator-iph6a38eb783/26/ios/26) | The bundled calculator offers basic/scientific arithmetic, conversions, history, and Math Notes with graphing. | Merely adding scientific buttons or history is not a compelling differentiator. A new calculator needs a distinctive experience people actively prefer. |
| [PCalc](https://pcalc.com/ios/index.html) | Deep scientific/programmer functionality, optional RPN, customizable layouts, conversions, paper tape, and broad Apple-platform support. | Do not attempt a feature-for-feature engineering calculator. Borrow respect for established workflows, visible history, and user control. |
| [Calcbot](https://tapbots.com/calcbot/) | A friendly utility built around expression visibility, history, conversion, and personality. Its [App Store listing](https://apps.apple.com/us/app/calcbot-2/id376694347) describes custom sounds and animations. | Personality and practical utility can coexist. Keep the active entry readable and give correction and history obvious controls. |
| [Soulver](https://soulver.app/) | A notepad and natural-language calculator for contextual calculations. The current [Soulver 4 listing](https://apps.apple.com/us/app/soulver-4/id1508732804) describes variables, specialized input keyboards, references, exports, and sync. | Remembering a result's context matters. Give saved calculations their expression; defer text parsing and document management rather than shipping a weak imitation. |
| [(Not Boring) Calculator](https://apps.apple.com/us/app/not-boring-calculator/id1533591596) | The closest playful competitor: bold 3D presentation, game-inspired sound/motion, readable expressions, editing, and visual skins. Its listing reports no data collected and offers both membership and lifetime in-app purchases. | “A calculator, but fun” is already occupied. Oddly should offer its own quiet, absurd personality, useful science/history, and an inspectable open-source implementation. Do not copy its visual skins or game treatment. |

## Signals and design hypotheses

Calcbot's App Store reviews include conflicting preferences about live results: one praises calculation speed; another finds the active operand harder to follow when the predicted result takes its place. This suggests an interaction choice worth testing, not evidence of a universal preference. Oddly will keep the number being entered in the largest type and show the pending operation separately. [Calcbot listing](https://apps.apple.com/us/app/calcbot-2/id376694347)

The playful competitor's listing contains older reviews requesting more advanced arithmetic. That is a plausible opportunity to combine personality with common scientific functions, but it does not establish what its current version lacks. Oddly should describe its own tested functions instead of claiming superiority. [(Not Boring) listing](https://apps.apple.com/us/app/not-boring-calculator/id1533591596)

The broad hypothesis is that people who appreciate well-crafted everyday objects may welcome humor that respects their attention. The product should feel like a helpful desk companion: immediate arithmetic, clear corrections, a small response when something interesting happens, and optional discoveries. Validate this with task completion and comfort, not time spent in the app.

## Product decision

Build **Oddly**, a native, offline calculator with a warm paper-like visual identity, dependable decimal arithmetic, useful scientific functions, local history and recall, and a collection of family-friendly numerical curiosities. Three personality levels control written humor and brief optional discovery decoration. Haptics and motion remain independently controlled. There is no ad network, tracking SDK, account, subscription, or backend in v1.

The launch proposition is **“Serious math. Tiny nonsense.”** Open source makes the calculation and privacy implementation inspectable. It is a product attribute, not a substitute for a good calculator. “Oddly” is a working brand; availability and naming rights have not been established by this research. A final public-listing check found [Oddly: AI Match Odds Generator](https://apps.apple.com/ro/app/oddly-ai-match-odds-generator/id6758236309) in Sports, so the short name is already used by another app. The proposed full calculator title must be checked in App Store Connect before release; search results do not establish availability.

## Release implications

App Review requires accurate metadata, a complete working product, functional support information, and specific documentation of non-obvious behavior. List every Easter-egg trigger and where to find personality settings and the collection in the review notes. The open-source code and a successful local build alone do not establish App Store readiness or approval. [Apple App Review Guidelines, sections 1.5, 2.1, and 2.3](https://developer.apple.com/app-store/review/guidelines/)

Use accessible touch targets and clear press states. Apple's design guidance calls for controls of at least 44 × 44 points; Oddly targets 52 points or more for calculator keys. [Apple UI Design Dos and Don'ts](https://developer.apple.com/design/tips/)
