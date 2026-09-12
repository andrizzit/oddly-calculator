# Oddly product and architecture decisions

Working brand: **Oddly**. Promise: **Serious math. Tiny nonsense.** This document records the design decisions agreed by the control room, designer/architect, funny designer, and implementer. QA owns independent validation. It describes the intended product; build and device verification must be reported separately.

## Experience

Open straight into a working calculator. The number being entered stays large and easy to check. A smaller operation line describes the calculation that will actually run. Backspace and clear are visible. History stores meaningful calculations and recalls their result. Scientific shortcuts (square, square root, reciprocal, and pi) are available in portrait through an explicit control. Trigonometry and angle modes are outside v1.

The main screen feels like an unusually charming desk instrument. Its small geometric companion can react to a completed result, while the result and every key remain available. New discoveries appear in a local collection. A discovery never launches a modal, changes a number, moves a key, or delays the next calculation.

The core user journeys are: calculate and correct an entry; apply a percentage or scientific function; revisit and reuse a history item; discover and inspect a curiosity; choose a calmer personality; turn off haptics. All must work offline and without onboarding or registration.

## Visual system

| Token | Color | Use |
| --- | --- | --- |
| Paper | `#F5F1E8` | Main canvas |
| Ink | `#202522` | Primary typography and symbols |
| Ivory | `#FFFCF5` | Number keys |
| Tangerine | `#F26B38` | Equals and operator accents |
| Lavender | `#DCD5F6` | Utility/scientific surfaces |
| Sage | `#D9E7D8` | Companion/status area |

Use ink on accent fills; white text on orange is not the default. Build the mascot and visual ornament in native shapes so the app needs no external image assets for the main interface. The app icon should be original, legible at small sizes, and visually related to the companion.

Main layout: brand at the top left, History and Settings at the right; calculator mode control; a spacious result region; a reserved companion message region; four columns of rounded square keys. Prefer roughly 20-point corner radii, 10-point gaps, and 52-point minimum calculator-key height. Use a large system monospaced or rounded numeric face for the display and system text for supporting UI. Zero may span two columns if backspace remains easy to reach.

The layout must adapt rather than compress indefinitely. On small screens, landscape, or large Dynamic Type sizes, allow vertical scrolling and preserve usable keys. Center a bounded calculator width on iPad and wide desktop windows. Secondary panels should use native navigation, lists, and dismissal affordances. No custom visual treatment should obstruct their accessibility.

## Calculation contract

The team considered a precedence parser. The implementer advocated the familiar pocket-calculator model to support predictable contextual percentages and repeat equals; the designer objected to displaying an expression whose conventional mathematical reading would contradict the result.

**Resolution:** v1 evaluates binary operations as entered and shows only the actual pending or completed operation. Entering `2 + 3 ×` displays `5 ×`, then entering `4 =` produces `20` with `5 × 4 =` above it. Never show the misleading expression `2 + 3 × 4 = 20`. Explain immediate execution plainly in calculator help. Do not advertise expression parsing or parentheses.

Use Foundation `Decimal` for basic arithmetic, retaining numeric state independently of formatted text. Keep error handling explicit for divide by zero, invalid domains, and overflow. Scientific operations may use floating-point functions, with their rounding and range limits documented and tested. A display-rounded value must not silently replace the internal result during normal chaining.

Percent behavior must be covered by examples: `200 + 10% = 220`, `200 − 10% = 180`, `200 × 10% = 20`, `200 ÷ 10% = 2000`, standalone `10% = 0.1`. Repeated equals repeats the last completed binary operation. Scientific functions apply to the current operand. Errors remain readable and recover with the next valid entry or clear; `NaN` and infinity must not become normal saved results.

## Personality contract

The designer proposed one Fun toggle to reduce complexity; the control room retained three levels for the requested personality range. The funny designer constrained them to content and frequency, preserving the same calm interaction pattern:

- **Calm:** no unsolicited jokes or new discovery reactions.
- **Playful:** first-time discoveries and occasional short quips.
- **Unhinged:** more absurd copy at a higher frequency, with the same non-blocking UI.

Evaluate triggers only after completed calculations. Suppress repeated-result spam and already-discovered announcements. Store discoveries on device. No daily streaks, pressure, notifications, random fake errors, or rewards for unnecessary activity. Copy jokes about numbers or an imaginary calculator world; never insult a user's competence. Avoid sexual calculator words, licensed character art, copied quotations, and jokes about sensitive personal characteristics.

Keep the personality system independent of the calculator. It receives a completed result, operation context, count, previous result, and known discoveries; it returns optional presentation copy and a discovery identifier. It cannot write numeric state. The implementation's exact trigger catalogue is authoritative for QA and App Review notes.

## Native architecture

Target SwiftUI on iOS 17 and later, with no third-party package dependencies. Keep Foundation-only logic in a local package or clearly isolated core module so numeric and personality behavior can be tested without an iOS simulator.

| Responsibility | Boundary |
| --- | --- |
| Calculator engine | Value-oriented numeric state, supported actions, display metadata, typed failures. No SwiftUI, persistence, haptics, or jokes. |
| Personality engine | Deterministic result-trigger evaluation and copy selection; no access to engine mutation. |
| Application model | Main-actor coordination of calculator actions, history, settings, discoveries, and user feedback. |
| Local storage | Codable records or property-list preferences; bounded history; recoverable decoding; explicit deletion. Store canonical numeric strings for recall. |
| SwiftUI views | Adaptive presentation, labeled controls, native sheets, focus/navigation, motion preferences, and user-triggered copy/share. |

Recommended record fields are a stable identifier, timestamp, visible operation, canonical result, and display result. Persist settings and discovery identifiers independently from history deletion. Do not silently replace meaningful saved data because one entry fails to decode.

## Accessibility and acceptance

Use explicit VoiceOver labels for mathematical symbols, mode controls, backspace, and clear. The result must be readable independently of decorative copy. Do not announce every quip as a live interruption. Pair color cues with text or shape. Each custom button changes its background color on press. An 80 ms activation highlight also covers quick taps, with a 160 ms release fade; actions run immediately and keys stay stationary. Honor Reduce Motion by retaining the color change without the fade. Feedback must never be essential to understanding the current state. Provide a separate haptics preference. Apple's minimum touch-target guidance is 44 × 44 points; calculator keys target at least 52 points. [Apple design guidance](https://developer.apple.com/design/tips/)

Independent QA should test decimal correctness, percent and repeat-equals semantics, operator replacement, sign/delete/clear transitions, scientific domains, formatting boundaries, history recall, persistence, personality suppression, and full recovery from errors. Visual QA must include the smallest supported phone layout, an ordinary phone, landscape, an iPad layout, large text, VoiceOver navigation, and Reduce Motion. A macOS fallback preview is useful evidence for shared SwiftUI behavior but does not substitute for iOS build, simulator, and device checks.

App Store review notes must disclose non-obvious discoveries with exact reproduction steps. Release status must distinguish implemented code, tests actually run, signed device build, TestFlight, submission, and published availability. [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
