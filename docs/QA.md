# Testing Oddly

Use Xcode 26 or later with an installed iOS Simulator runtime. Select the installed Xcode under Settings > Locations > Command Line Tools.

## Automated checks

Run from the repository root:

```sh
swift test
bash scripts/test-model.sh
python3 scripts/validate-project.py
bash scripts/test-ios.sh
```

| Check | What it covers |
| --- | --- |
| `swift test` | Foundation calculator state, decimal arithmetic, percentages, repeated equals, scientific operations, range errors, history serialization, and deterministic personalities/discoveries. |
| `scripts/test-model.sh` | The application's coordinator, saved preferences, history recovery, discovery state, and explicit deletion. Runs on macOS in an isolated preference domain. |
| `scripts/validate-project.py` | Property lists, privacy manifest, Xcode project references, shared scheme, and app icon/assets. |
| `scripts/test-ios.sh` | Native XCUITest workflows for calculations, sheets, persistence, discoveries, appearance, accessibility text sizes, landscape, and press cancellation/scrolling. |

The CI workflow runs these checks and verifies that the committed Xcode project matches `scripts/generate-project.py`. When adding or removing app source files, regenerate the project and include that change in the pull request.

To choose an available Simulator, run `xcrun simctl list devices available`, then supply its identifier:

```sh
SIMULATOR_ID=YOUR_SIMULATOR_ID bash scripts/test-ios.sh
```

For a focused check, use Xcode's Test navigator or `xcodebuild test` with the Oddly scheme and an `-only-testing:OddlyUITests/OddlyUITests/TEST_METHOD` argument. Include the change, relevant test results, and any remaining limitations in your pull request.

UI tests reset Oddly's saved data through `--uitesting-reset` before each case; relaunches without that argument verify persistence. `--uitesting-large-type` selects accessibility3 and `--uitesting-largest-type` selects accessibility5. These launch arguments are compiled only into Debug builds.

## Manual checks

Use fictional calculations on a small iPhone, a large iPhone, and an iPad. Repeat relevant flows in portrait, landscape, both appearances, and the largest Dynamic Type size.

- Calculate `0.1 + 0.2 = 0.3` and `2 + 3 × 4 = 20`. Check the second calculation's displayed operation becomes `5 × 4 =`. Verify contextual percentages, repeated equals, sign changes, delete, Clear, and fresh entry after a result.
- Divide by zero or take the square root of a negative value. Check the error is readable, no invalid history item is saved, and entering a digit recovers immediately.
- Try square, square root, reciprocal, and pi within a pending calculation. Copy and recall a long result and confirm they preserve its stored precision.
- Complete the [discovery hints](HUMOR_DESIGN.md), then repeat them. Check each discovery is saved once, input stays available, and Calm pauses new discoveries without deleting existing ones.
- Reopen the app and confirm history, preferences, and discoveries persist. Clear history and confirm preferences/discoveries remain. Repeat normal use in Airplane Mode.
- Tap and hold keys in both appearances. Drag off a key to cancel; scroll from a key when the layout overflows. Check feedback is visible and no unintended digit is entered.
- Navigate the result, every control, and all sheets with VoiceOver. Check literal mathematical labels, focus order, and that jokes do not interrupt navigation. Verify complete controls remain reachable at the largest text size.
- On a physical iPhone, check haptics both enabled and disabled and verify Reduce Motion. Press color feedback should remain visible with Reduce Motion enabled.

## Known limitations

Oddly uses finite-precision Foundation `Decimal`, with an 18-digit manual entry limit. Nonterminating results round; display formatting can abbreviate a stored result. Some extreme operations may return a range error before reaching Decimal's nominal storage limits. A correct result or explicit error is required; silent exponent wrap, a fabricated zero, NaN, or infinity is not acceptable. See the [calculation contract](PRODUCT_DESIGN.md).

Core and coordinator checks do not exercise iOS layout. Simulator reachability assertions cover only part of accessibility; physical-device checks are needed for haptic feel and VoiceOver interaction. A macOS preview is a development aid and does not verify the iPhone or iPad interface.
