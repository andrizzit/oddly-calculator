# Oddly independent QA

This report separates tests that execute the Foundation calculator on macOS from tests that launch the actual iOS application. A desktop preview, source review, or generated image is not evidence that iOS layout, signing, or App Store delivery works.

## Automated coverage

`Tests/CalculatorCoreTests/CalculatorEngineTests.swift` covers the implementer's expected workflows. `Tests/CalculatorCoreTests/AdversarialTests.swift` is owned by independent QA and checks those decisions from a separate oracle:

- Signed integer addition, subtraction, and multiplication against Swift integer arithmetic for 147 operand/operator combinations.
- Exact decimal money arithmetic, repeating fractions without premature display rounding, representable boundaries, explicit underflow/overflow, perfect square roots across large and tiny magnitudes, and invalid recall preserving a pending operation.
- Immediate execution and its honest breadcrumb (`2 + 3 × 4 =` produces `20` and displays `5 × 4 =`); contextual and negative percentages; repeated equals using the resolved percentage operand; fresh decimal entry; delete; pending reciprocal and pi; domain errors and recovery.
- History ordering, the 100-record cap on append and decode, canonical decimal recall, record identity and dates, and corruption surfacing as a decoding failure rather than a fabricated empty history.
- Every documented Easter egg, exact positive matches and near misses, unique stable IDs, Calm suppression, saved discoveries, repeated-result suppression, deterministic copy and its cadence, and invalid numeric input.

`OddlyUITests/OddlyUITests.swift` launches the real application for eleven workflows: arithmetic and repeat equals; decimals and percentages; delete and error recovery; portrait scientific tools; history after process relaunch and recall; persistent discoveries without blocked input or moved keys; Calm mode persistence and suppression; clearing history while preserving discoveries; large text in landscape with reachable touch targets; the largest accessibility size in all three secondary panels; and landscape arithmetic at that largest size. It saves real simulator screenshots for the visual and accessibility cases.

Run the core suite with `swift test` under full Xcode. Run the actual model's recovery/settings checks with `bash scripts/test-model.sh`; its fixture is `scripts/check-model.swift`, and it creates and cleans an isolated preference domain. The iOS suite is available through `bash scripts/test-ios.sh` or the Oddly scheme's Test action. UI tests use an explicit `--uitesting-reset` launch argument to clear only the application's own preferences before each test; a subsequent launch without it verifies persistence. `--uitesting-large-type` selects accessibility3; `--uitesting-largest-type` selects accessibility5, the largest supported size. Test launch flags are compiled only in Debug builds.

## Release verification matrix

| Gate | Required evidence |
| --- | --- |
| Foundation core | A successful run of all Swift Testing suites, with toolchain and date recorded. |
| iOS build | A successful build of the actual Oddly target using an iOS SDK. |
| iOS UI workflows | Passing XCUITest results from an installed iOS Simulator runtime. |
| Small phone and ordinary phone | Portrait/landscape screenshots and usable controls, including the longest result, error message, and Unhinged reaction. |
| iPad | Bounded calculator width, working sheets, portrait/landscape and window resizing. |
| Accessibility | Largest Dynamic Type, VoiceOver reading/focus order, literal math labels, contrast, 44-point minimum targets, Reduce Motion, and haptics preference. Automated reachability checks cover only part of this gate. |
| Persistence and privacy | Reopen preserves history/settings/discoveries; clearing history preserves settings/discoveries; no network/account/analytics flow; malformed local data has a recoverable explanation. |
| Physical device | Install and exercise a signed build on an actual iPhone, including haptics and accessibility behavior. |
| Distribution | Apple Developer membership, unique bundle ID, signing team, successful archive and App Store validation, public support/privacy links, and required App Store Connect metadata. |
| App Store | TestFlight verification, submission, Apple's review, and a publicly available listing. A build or upload alone does not pass this gate. |

## Manual acceptance procedure

1. Calculate `0.1 + 0.2 = 0.3`; `2 + 3 × 4 = 20`; each of `200 + 10%`, `200 − 10%`, `200 × 10%`, and `200 ÷ 10%`; then repeat equals and check the displayed operation.
2. Enter and delete a negative decimal. Replace an operator before its right operand. Start a new number and a new decimal after equals. Confirm that no previous operand survives Clear.
3. Divide by zero and take the square root of a negative value. Confirm readable, literal errors, no saved invalid result, and immediate recovery by valid entry or Clear.
4. Open Math in portrait; try square, root, reciprocal, and pi within a pending calculation. Copy a long result and recall it from history; the precision must agree.
5. Complete the eight hint expressions from `HUMOR_DESIGN.md`. Confirm one discovery per item, no modal or key movement, accurate collection state after relaunch, and immediate continued input.
6. Choose Calm, complete an undiscovered hint, and confirm no new discovery or unsolicited quip. Confirm changing modes never changes arithmetic or deletes previous discoveries.
7. Reopen after calculations and preference changes. Clear history and verify that discoveries and preferences remain. Test the app offline.
8. Repeat the primary workflows on a small phone, an ordinary phone, and iPad, including landscape and largest accessibility text. Check every key is reachable without overlap; read a long error and the longest personality message.
9. Enable VoiceOver. Navigate the result and all mathematical keys, sheets, discovery hints, and preferences. Confirm jokes do not seize focus. Enable Reduce Motion and disable haptics; confirm preferences are honored on a real device.

## Findings and execution evidence

On 11 September 2026, independent QA ran the package using Xcode 26.6 (17F113), Apple Swift 6.3.3, on arm64 macOS. **All 47 Swift Testing test functions in three named QA suites plus the implementer tests passed.** Parameterized tests also covered four percent cases, six recovery actions, and twelve invalid recalls; the integer oracle contains 147 combinations. The separate XCTest compatibility runner reports zero tests because this package uses Swift Testing; the later Swift Testing result is the relevant total.

The macOS package result verifies Foundation code. Separate native iOS evidence is available: **all nine XCUITest workflows passed on an iPhone 16 Pro Max simulator running iOS 26.5**, using Xcode 26.6. The full run was launched through `scripts/test-ios.sh`; its result bundle is `build/TestResults-1789164704.xcresult`, with console output in `build/qa-final-ui.log`. It includes real screenshots of the result, discovery, cabinet, settings, and large-text landscape. Physical-device and App Store gates remain separate.

An additional isolated macOS harness compiled the actual `CalculatorViewModel` with the tested core and passed 18 coordinator assertions: corrupt data backup and warning, continued calculation without destroying the backup, mode-change discovery behavior, restored history/settings/discoveries, and clearing history/recovery data while retaining preferences and discoveries. This supplements the iOS persistence workflows; it does not claim real-device testing.

Focused final checks passed after the touch-area repairs: delete, history copy, and cabinet controls expose at least 44 × 44 points; the cabinet opens from its full row; discoveries preserve key positions. The large-text landscape check waits for landscape orientation, scrolls as needed, and requires the complete equals key to fit inside the app's bounds. It passed against the final responsive layout in `build/UITests-final-landscape.xcresult`; the whole-screen screenshot was visually reviewed and shows a complete, readable keypad. The earlier focused run's landscape failure was caused by stopping the test's scroll once a partially visible key was considered hittable; the strict full-visibility assertion was retained.

Two additional workflows passed on an **iPhone SE (3rd generation), iOS 26.5, at accessibility5**, the largest Dynamic Type size. Settings scrolled to its final About row; History reached the oldest of eight records; the cabinet reached and expanded its eighth hint; and each sheet's Done button remained usable. This panel workflow passed in `build/UITests-small-accessibility.xcresult`. Landscape arithmetic `6 × 7 = 42` passed in `build/UITests-small-landscape.xcresult`, requiring every tapped key to be hittable, at least 44 × 44 points, and fully inside the app's bounds after scrolling. Screenshots were exported to `build/qa-small-accessibility-attachments` and `build/qa-small-landscape-attachments` and visually reviewed. The first landscape attempt failed because the test's app-wide down-swipe opened iOS Notification Center; its real recording identified the cause. The helper now uses short interior drags in landscape and retains the same assertions. No production layout change was needed.

To repeat these two targeted checks on a chosen small-phone simulator, substitute its ID below (or run all eleven workflows with `scripts/test-ios.sh`):

```sh
xcodebuild test -project Oddly.xcodeproj -scheme Oddly \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' \
  -derivedDataPath build/DerivedData \
  -only-testing:OddlyUITests/OddlyUITests/testLargestTextSecondaryPanelsScrollAndDismiss \
  -only-testing:OddlyUITests/OddlyUITests/testLargestTextLandscapeArithmeticRemainsReachable \
  CODE_SIGNING_ALLOWED=NO
```

The control room also verified the final iPad portrait layout: a centered, bounded calculator with readable controls and no clipping, captured in `docs/assets/oddly-ipad-calculator.png`. Its visual review also covered the iPad landscape layout and settings sheet, and standard small-phone layout and dark appearance. Sampled production sRGB text color pairs exceeded 4.5:1 contrast (the lowest sampled ratio was 5.14:1); this verifies those pairs only. It built the current sources into `build/Oddly-1.0.0-ReleaseCandidate.xcarchive`, checked metadata and the privacy manifest, and confirmed all three UI-test launch switches are absent from Release. This verifies a native Release archive; it is unsigned and is not a signed-device, TestFlight, or App Store release.

Remaining release gates: signed installation on a physical iPhone; real-device VoiceOver navigation and announcement behavior; haptics and Reduce Motion; Apple Developer membership, signing and App Store Connect setup; TestFlight; and Apple's review/publication. Automated simulator reachability and label checks cover only part of accessibility validation.

The tested engine SHA-256 was `c158af0d36ba3addb1f3d4d53fdf04de22d52abdbadc42b246245b15aab71e8d`. Later production changes require the relevant checks to run again.

QA findings corrected before this pass:

- Pi used as a right operand could incorrectly replace a pending operation when the next operator was pressed. Its state now distinguishes replacing an entry from waiting for an operand.
- A new digit after percentage/scientific transformation could append to the transformed operand; signed pi could block entry because its full-precision value exceeded the entry limit. Computed values now yield to fresh number entry, while signed manual entries remain editable.
- Restoring history bypassed its 100-record cap. Custom decoding now enforces the same bound as initialization and append.
- Native Foundation multiplication reported success while wrapping an extremely small exponent: `(1e−100)²` became `1e56`. A sequence reachable using ordinary keys also failed: enter `10000000000`, reciprocal, then square four times. The engine now independently checks multiplication/division magnitude and rejects wrapped results, while retaining Decimal for the actual arithmetic. All reproduction and overflow/underflow regressions pass.
- Corrupt stored history was silently treated as empty. The application now preserves the failed payload in a local recovery backup and displays a history notice. The actual model's recovery and explicit-clear behavior passed the supplemental harness.
- Initial layout math allocated too much height to keys on ordinary phones. The available-height calculation and companion reservation were adjusted; the native iPhone and iPad screenshots and the focused landscape check verify the reviewed layouts.
- The cabinet link's plain label exposed only its text as a touch area; tapping the middle of its row did not open the collection. The full label now has an explicit hit shape. The three previously failing collection workflows pass in the full iOS rerun. Related delete/history-copy hit areas were repaired and passed focused minimum-size checks.

Range limitation: Foundation may reject an extreme operation before the final value reaches Decimal's storage bound. For example, `1e−100 ÷ 10` returns an explicit range error on the tested framework, while `1e−80 ÷ 10` remains accurate. QA requires either the accurate extreme result or an explicit range error; it rejects zero, exponent wrap, NaN, and fabricated success. The app is not an arbitrary-precision calculator.
