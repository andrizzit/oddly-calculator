# Screenshot capture plan

Capture the actual iOS Simulator/device app after the iOS build passes. Do not submit conceptual renders or the macOS development preview. The prepared targets are iPhone 16 Pro Max at 1320 × 2868 and iPad Pro 13-inch at 2064 × 2752. These match the current [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/). Recheck those specifications before submission.

Suggested sequence, with fictional data only:

1. Main calculator: enter 128 × 4 =. Caption suggestion: “A little room to think.”
2. First discovery: on a fresh app installation, enter 6 × 7 = in Playful mode. Caption: “Serious math. Tiny nonsense.”
3. History: perform several varied calculations, open History. Caption: “Good answers deserve a paper trail.”
4. Collection: open after discovering several numbers, showing both collected items and hints. Caption: “Eight little reasons to be curious.”
5. Appearance/personality settings or a dark-theme calculator. Caption: “Your kind of odd.”

For a running simulator:

```sh
xcrun simctl io booted screenshot build/oddly-iphone.png
```

The XCUITest suite also attaches screenshots to its result bundle where specified. Review screenshots for accurate results, readable text, supported dimensions, consistent status bars, no developer diagnostics, and no personal data. Screenshots must match the version being submitted. Use only the app's original assets or artwork you own.

## Captured assets

`docs/assets/oddly-iphone-*.png` are untouched 1320 × 2868 RGB captures from the passing iPhone 16 Pro Max UI suite. `docs/assets/oddly-ipad-calculator.png` is an untouched 2064 × 2752 capture of the actual iPad Pro 13-inch app. No mockups, altered results, or alpha channels are used. The discovery screenshot captures the brief party-hat animation. Recheck the final signed binary before submitting these assets.
