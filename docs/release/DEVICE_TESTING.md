# Test on your iPhone

The app has no restricted capabilities, so local testing can use a personal Apple Account in Xcode. App Store and TestFlight distribution require an active Apple Developer Program membership. [Apple's signing workflow](https://help.apple.com/xcode/mac/current/en.lproj/dev60b6fbbc7.html)

1. Open `Oddly.xcodeproj` in Xcode and sign in through Xcode Settings > Apple Accounts.
2. Connect and unlock your iPhone. Complete any Trust This Computer prompts on the phone.
3. Enable Developer Mode when Xcode requests it. Apple documents the device settings and restart flow in [Enabling Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
4. Copy `Oddly/Signing.example.xcconfig` to the ignored `Oddly/Signing.xcconfig`. Set your real `DEVELOPMENT_TEAM` and a unique `ODDLY_BUNDLE_IDENTIFIER`. Xcode displays the chosen team in the app target's Signing & Capabilities pane.
5. Select **Oddly** and your physical iPhone as the run destination, then press Run. Let Xcode finish device preparation. [Apple's device-running guide](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)

For the project's owner's iPhone 16 Pro Max, check these flows with made-up numbers:

| Check | Expected behavior |
| --- | --- |
| Tap quickly through `12.5 × 8 =` | 100; no missed taps or blocked keys |
| `200 + 10% =` | 220 |
| `8 ÷ 0 =`, then type 9 | Readable error, then immediate recovery to 9 |
| `6 × 7 =` in Playful | 42 and Cosmic Receipt discovery; next digit works immediately |
| Haptics on/off in Settings | Gentle feedback when enabled; none when disabled |
| History, terminate app, reopen, recall | Saved values persist exactly and can be reused |
| Turn on Calm | No new jokes or discoveries |
| Dark appearance | Readable controls and clear selected operator |
| Larger Text and landscape | Scroll if needed; every key remains reachable |
| VoiceOver | Correct mathematical labels, readable result, usable sheets; jokes do not interrupt input |
| Reduce Motion | Decorative motion stops; numbers and controls still work normally |
| Airplane Mode | All app functions continue to work |

Record the iOS version, app version/build, and any failures in `docs/QA.md`. Simulator success does not establish physical haptic quality or VoiceOver usability.
