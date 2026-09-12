# Shipping Oddly

## Current release gate

The source and release materials can be prepared without membership. App Store publication requires an active Apple Developer Program membership, a signed iOS archive, an App Store Connect app record, and Apple's review. **A source repository or a successful macOS test is not an App Store release.** See `../QA.md` for actual verification results.

Verified on September 11, 2026: Xcode 26.6 and the iOS 26.5 Simulator are installed, GitHub CLI authentication works, all 47 core tests, 18 coordinator checks, nine baseline native iOS workflows, and two supplemental largest-text workflows pass. The subsequent press-feedback update passed five focused iOS workflows and produced `build/Oddly-PressFeedback-Unsigned.xcarchive`, with metadata, privacy manifest, and exclusion of Debug test switches verified. A development build was signed with the publisher's Personal Team and installed on an iPhone 16 Pro Max running iOS 26.6.2. The publisher has no active Developer Program membership yet; physical-device accessibility and haptics verification and distribution setup remain required.

## 1. Install and test

Install [Xcode](https://developer.apple.com/xcode/) and finish its first-launch setup, including an iOS Simulator runtime. In Xcode Settings > Locations, select that Xcode installation for Command Line Tools. Alternatively, set `DEVELOPER_DIR` for the terminal session to the installed Xcode app's `Contents/Developer` path.

```sh
swift test
bash scripts/test-model.sh
python3 scripts/validate-project.py
bash scripts/test-ios.sh
```

Open `Oddly.xcodeproj`, select the shared Oddly scheme, and run on an iPhone. Test a small phone, a large phone, iPad, landscape, large accessibility text, dark theme, Reduce Motion, VoiceOver, rapid input, and persistence after termination. Test haptics on a physical iPhone. Capture screenshots from the actual iOS build; the macOS preview must not be submitted as an iPhone screenshot.

As of September 11, 2026, uploads require **Xcode 26 or later with the iOS 26 SDK or later**. Deployment remains iOS 17+, so users do not need iOS 26. Recheck [Apple's upload requirements](https://developer.apple.com/news/upcoming-requirements/) before release.

## 2. Configure publisher identity

Enroll in the [Apple Developer Program](https://developer.apple.com/programs/enroll/), sign in under Xcode Settings > Accounts, and choose the correct team. The owner must complete identity verification and agreements.

Copy `Oddly/Signing.example.xcconfig` to `Oddly/Signing.xcconfig`. Set `DEVELOPMENT_TEAM` and `ODDLY_BUNDLE_IDENTIFIER` to your actual team and registered bundle values. The app and UI-test runner inherit this shared identity; the runner adds its own suffix. The private file is ignored by Git. `com.example.oddly.calculator` is a buildable development placeholder, never the intended production identifier. Do not commit certificates, keys, or provisioning profiles.

Choose and verify the final app name in App Store Connect. **Oddly is a working brand; no trademark or App Store name availability clearance has been performed.** If the name changes, update source, icon if needed, display name, screenshots, and metadata consistently.

## 3. Create the App Store Connect record

Create a new iOS app matching the registered bundle ID, English primary language, and a stable publisher-chosen SKU. Use `METADATA.md` as the starting copy. Decide pricing and territories. No in-app purchases or subscriptions are implemented.

Before submission, complete:

- Working support URL and a monitored support contact.
- Public HTTPS privacy policy URL containing the final policy in `../PRIVACY.md`.
- App privacy answers: the app itself collects no data. Confirm this still matches the submitted binary and any future dependencies.
- The current age-rating questionnaire, answered from the actual app's content.
- Export compliance. The current app has no custom encryption or networking; `ITSAppUsesNonExemptEncryption` is false.
- Rights/copyright, contact details, territories, and any applicable trader declarations in the account.

These publisher facts must be entered by the actual owner; do not fabricate names, addresses, URLs, or declarations. The draft privacy policy's final setup paragraph should be replaced by the real support contact when hosted.

## 4. Archive and distribute

```sh
bash scripts/archive.sh
```

Open `build/Oddly.xcarchive` with Xcode Organizer, validate it, then choose Distribute App > App Store Connect. The script archives locally and does not submit anything. Resolve signing issues with Xcode's Accounts/Signing UI. Bump the build number before a subsequent upload of the same version.

Use TestFlight on real devices and finish the QA checklist. Paste `REVIEW_NOTES.md` into Notes for Review. Upload real screenshots following `SCREENSHOTS.md`. Submit only after all required release gates have passed. Apple's review and acceptance are external; approval cannot be guaranteed.

References: [upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds), [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
