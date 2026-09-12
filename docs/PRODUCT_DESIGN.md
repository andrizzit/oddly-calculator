# Architecture and behavior

Oddly is a SwiftUI calculator for iOS 17 and later. Its local `CalculatorCore` Swift package contains Foundation-only calculation, history, and personality models. The app has no third-party package dependencies or networking.

## Responsibilities

| Component | Responsibility |
| --- | --- |
| `Sources/CalculatorCore/CalculatorEngine.swift` | Calculator state, key actions, canonical results, visible operations, and typed errors. It has no UI, storage, or humor dependencies. |
| `Sources/CalculatorCore/CalculatorHistory.swift` | Codable calculation records and a bounded history, newest first. |
| `Sources/CalculatorCore/Personality.swift` | Deterministic reactions, discovery triggers, stable identifiers, and copy. It cannot change calculator state. |
| `Oddly/CalculatorViewModel.swift` | Main-actor coordination of input, persistence, display formatting, clipboard actions, result announcements, and haptics. |
| `Oddly/CalculatorView.swift` and `Oddly/LibraryViews.swift` | Calculator layout and the history, settings, and collection sheets. |
| `Oddly/Components.swift` and `Oddly/DiscoveryCelebration.swift` | Shared palette, button feedback, native mascot shapes, and finite discovery animation. |

Keep arithmetic and personality logic independent of SwiftUI. Pass key actions through the view model; views should not duplicate calculations or write stored preferences independently.

## Calculation contract

Binary operations execute as entered. Entering `2 + 3 ×` resolves the addition and shows `5 ×`; entering `4 =` then produces `20` with `5 × 4 =` above it. The operation line must describe the operation actually performed, without implying algebraic precedence.

| Input | Result |
| --- | --- |
| `0.1 + 0.2 =` | `0.3` |
| `200 + 10% =` | `220` |
| `200 − 10% =` | `180` |
| `200 × 10% =` | `20` |
| `200 ÷ 10% =` | `2000` |
| `10% =` | `0.1` |
| `5 + 2 = =` | `9` |

Repeated equals reuses the last binary operator and resolved right operand. Entering another operator before a right operand replaces the pending operator. New digits after a completed result start a fresh entry. Scientific shortcuts apply square, square root, or reciprocal to the current operand; pi inserts the stored constant.

Arithmetic uses Foundation `Decimal`, with an 18-digit manual entry limit. Square root uses decimal Newton iteration after a floating-point seed. Multiplication and division also check the result's magnitude independently to detect exponent overflow. These checks do not supply the arithmetic result. Nonterminating results round to Decimal's precision.

The engine retains canonical numeric text and decimal operands. `formattedDisplay` may abbreviate a long number for presentation; chaining, copying, recall, and accessibility use the canonical value. Never feed abbreviated display text back into a calculation. Invalid domains and out-of-range results produce recoverable errors and no history record. A new numeric entry or clear resets the error state.

`press(_:)` returns a history record on successful equals and standalone unary operations. Unary operations inside a pending binary calculation update its operand without saving a separate record. Operator chaining itself does not create a history entry.

## Local persistence

The view model stores preferences, discovery identifiers, and the completed-equals count in `UserDefaults`. History is JSON-encoded under its own key. Each record contains a UUID, date, visible operation, and canonical result string. History keeps at most 100 records, including when decoded.

If history cannot be decoded, the app preserves a recovery copy before starting an empty working history. The History sheet displays a notice while that copy exists. Clearing history explicitly removes both working history and the recovery copy; it preserves preferences and discoveries. Resetting discoveries is a separate action. Keep stored discovery identifiers stable across catalogue edits.

## Personality and feedback

Reactions are evaluated only after successful equals. Calm suppresses reactions and pauses discoveries. Playful allows ordinary quips every fourth completed calculation; Unhinged allows them every second. First-time discoveries take priority over that cadence. Repeated identical results suppress reactions, and known discoveries are not announced again. Changing personality clears the current reaction and repeated-result suppression state.

Humor must never alter answers, delay actions, obscure controls, or move keys. Discovery animation remains within the mascot area, ignores input, and is hidden from accessibility. It is disabled by Reduce Motion. Button feedback changes color immediately, retains a brief activation highlight for quick taps, and removes the release fade with Reduce Motion. Haptics have an independent setting.

## Accessibility and layout constraints

Maintain explicit mathematical labels, a separate accessible result value, and visible clear and delete controls. VoiceOver announcements convey results or errors; jokes must not seize focus. Selected operators use an outline and accessibility state alongside color.

Calculator keys are at least 52 points high; toolbar and auxiliary touch controls use at least 44-point targets. Preserve vertical scrolling when height or larger text requires it. Wide landscape layouts place the result and keypad side by side, while other layouts stack them. Keep long results, errors, and companion messages readable when modifying spacing or typography. Palette and press-state colors live in `Components.swift` and support Paper, Midnight, and system appearance.
