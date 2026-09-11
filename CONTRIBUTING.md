# Contributing to Oddly

Bug reports, accessibility improvements, translations, and properly terrible number jokes are welcome. Discuss large changes in an issue first.

1. Fork and clone the repository. Use Xcode 26 or later for the iOS app.
2. Open `Oddly.xcodeproj`. The shared `Oddly` scheme uses a local Swift package with no third-party dependencies.
3. Run `swift test` for the portable core, `scripts/test-model.sh` for local storage recovery, then `scripts/test-ios.sh` for the app and UI tests.
4. Include the problem, resulting behavior, and test evidence in your pull request.

Keep arithmetic deterministic. Jokes cannot change numbers, move keys, block input, make network calls, or shame people. Every new Easter egg needs a deterministic trigger, hint, test, and entry in the App Review notes. Respect Calm, Reduce Motion, and VoiceOver. Do not log users' calculations.

The calculator evaluates binary operations immediately from left to right. Change that behavior only through an explicit product decision, with examples and tests.

Source, artwork, and contributions are MIT licensed. Submit only material you have the right to contribute. Do not commit credentials, provisioning profiles, personal signing configuration, or real calculation histories.
