import SwiftUI
import CalculatorCore

struct HistoryView: View {
    @ObservedObject var model: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var confirmClear = false
    private var palette: OddlyPalette { OddlyPalette(dark: colorScheme == .dark) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("THE PAPER TRAIL, MINUS THE PAPER.")
                        .font(.system(.caption2, design: .monospaced, weight: .semibold))
                        .foregroundStyle(palette.secondary)
                        .padding(.top, 8)
                    if let warning = model.historyRecoveryNotice {
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .padding()
                            .background(palette.utility, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if model.history.records.isEmpty {
                        VStack(spacing: 18) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 48, weight: .ultraLight))
                            Text("A fresh sheet.")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text("Your next answer starts the story.\nCalculations stay on this device.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(palette.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 70)
                    } else {
                        Text("Tap an answer to use it again. Your latest 100 calculations live here.")
                            .font(.footnote)
                            .foregroundStyle(palette.secondary)
                        LazyVStack(spacing: 10) {
                            ForEach(model.history.records) { record in
                                HStack(alignment: .center, spacing: 10) {
                                    Button {
                                        model.recall(record)
                                        dismiss()
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(record.expression + " =")
                                                .font(.system(.footnote, design: .monospaced))
                                                .foregroundStyle(palette.secondary)
                                            Text(record.result)
                                                .font(.system(.title2, design: .rounded, weight: .medium))
                                                .textSelection(.disabled)
                                                .foregroundStyle(palette.ink)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("\(record.expression), equals \(record.result)")
                                    .accessibilityHint("Use this answer in the calculator")
                                    .accessibilityIdentifier("history.recall.\(record.id.uuidString)")
                                    Button { model.copyResult(record.result) } label: {
                                        Image(systemName: "doc.on.doc")
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Copy \(record.result)")
                                }
                                .padding(17)
                                .background(palette.digit, in: RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    }
                }
                .padding(22)
            }
            .background(palette.background)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("history.done")
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear", role: .destructive) { confirmClear = true }
                        .disabled(model.history.records.isEmpty && model.historyRecoveryNotice == nil)
                        .accessibilityIdentifier("history.clear")
                }
            }
            .confirmationDialog("Clear all history?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) { model.clearHistory() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your saved calculations and any recovery copy from this device. Your discoveries stay.")
            }
        }
        .tint(palette.ink)
        .foregroundStyle(palette.ink)
        .preferredColorScheme(model.appearance.colorScheme)
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 600)
        #endif
    }
}

struct SettingsView: View {
    @ObservedObject var model: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var confirmReset = false
    private var palette: OddlyPalette { OddlyPalette(dark: colorScheme == .dark) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Personality", selection: $model.personality) {
                        ForEach(PersonalityMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.personality")
                    Text(model.personality.subtitle)
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                    Text("Calm pauses jokes and new discoveries. Every mode uses exactly the same math.")
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                } header: {
                    Text("A personality setting. Finally.")
                }

                Section("Make yourself at home") {
                    Picker("Appearance", selection: $model.appearance) {
                        ForEach(AppearanceChoice.allCases) { choice in
                            Text(choice.title).tag(choice)
                        }
                    }
                    .accessibilityIdentifier("settings.appearance")
                    #if os(iOS)
                    Toggle("Gentle haptics", isOn: $model.hapticsEnabled)
                        .accessibilityIdentifier("settings.haptics")
                    #endif
                    Text("Animations respect your device’s Reduce Motion setting. There are no sounds.")
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                }

                Section("A few useful things") {
                    helpRow("Operations run as entered", text: "2 + 3 × 4 gives 20. Each new operator completes the previous step; the line above the answer shows that step.")
                    helpRow("A percent that gets the context", text: "200 + 10% gives 220. For × and ÷, the percent becomes a fraction: 200 × 10% gives 20.")
                    helpRow("Again, again", text: "Press = again to repeat your last operation. 5 + 3 = gives 8; another = gives 11.")
                    helpRow("All your digits", text: "Enter up to 18 digits. Arithmetic uses Decimal, with up to 38 significant digits of precision. Very long answers use compact notation on screen; touch and hold the result to copy every available digit.")
                    helpRow("An easy way back", text: "Backspace removes a digit, cancels a pending operator, or clears a completed result. After an error, just enter a new number.")
                }

                Section("Private by design") {
                    Label("No accounts. No ads. No tracking.", systemImage: "hand.raised")
                    Text("Your calculations, settings, and discoveries stay on this device. Oddly makes no network requests. Clear saved calculations from History.")
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                }

                Section("The curiosity cabinet") {
                    HStack {
                        Text("Discoveries")
                        Spacer()
                        Text("\(model.discoveredEggIDs.count) of \(PersonalityEngine.catalogue.count)")
                            .foregroundStyle(palette.secondary)
                    }
                    Button("Rediscover everything", role: .destructive) { confirmReset = true }
                        .disabled(model.discoveredEggIDs.isEmpty)
                }

                Section {
                    HStack(spacing: 14) {
                        OddlyMascot(size: 42)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Oddly 1.0")
                                .font(.system(.headline, design: .rounded))
                            Text("Good with numbers. A little peculiar.")
                                .font(.footnote)
                                .foregroundStyle(palette.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(palette.background)
            .navigationTitle("Your kind of Oddly")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("settings.done")
                }
            }
            .confirmationDialog("Reset all discoveries?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset discoveries", role: .destructive) { model.resetDiscoveries() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All eight curiosities will be ready to find again. Your calculation history stays.")
            }
        }
        .tint(palette.ink)
        .foregroundStyle(palette.ink)
        .preferredColorScheme(model.appearance.colorScheme)
        #if os(macOS)
        .formStyle(.grouped)
        .frame(minWidth: 470, minHeight: 680)
        #endif
    }

    private func helpRow(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.subheadline.weight(.semibold))
            Text(text).font(.footnote).foregroundStyle(palette.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct CollectionView: View {
    @ObservedObject var model: CalculatorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var palette: OddlyPalette { OddlyPalette(dark: colorScheme == .dark) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 15) {
                        OddlyMascot(size: 65)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Small wonders.\nSuspicious arithmetic.")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text("\(model.discoveredEggIDs.count) of \(PersonalityEngine.catalogue.count) curiosities found")
                                .font(.footnote)
                                .foregroundStyle(palette.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    Text(model.personality == .calm
                         ? "Switch to Playful or Unhinged in Settings to discover more. Your existing collection is safe."
                         : "Some answers have a little extra to say. Complete a calculation with = to find them. A hint is here if you need one.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(PersonalityEngine.catalogue.enumerated()), id: \.element.id) { index, egg in
                            collectionCard(egg, index: index)
                        }
                    }
                }
                .padding(22)
            }
            .background(palette.background)
            .navigationTitle("Curiosity cabinet")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("collection.done")
                }
            }
        }
        .tint(palette.ink)
        .foregroundStyle(palette.ink)
        .preferredColorScheme(model.appearance.colorScheme)
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 640)
        #endif
    }

    private func collectionCard(_ egg: EasterEgg, index: Int) -> some View {
        let found = model.discoveredEggIDs.contains(egg.id)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: found ? egg.symbol : "lock")
                    .font(.system(size: 22, weight: .regular))
                    .frame(width: 48, height: 48)
                    .background(found ? palette.mint : palette.utility, in: RoundedRectangle(cornerRadius: 15))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(found ? egg.title : "Curiosity No. \(String(format: "%02d", index + 1))")
                        .font(.system(.headline, design: .rounded))
                    Text(found ? "FOUND. VERY NICELY DONE." : "WAITING TO BE FOUND")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(palette.secondary)
                }
                Spacer(minLength: 0)
                if found {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(palette.secondary)
                        .accessibilityHidden(true)
                }
            }
            if found {
                Text(model.personality == .unhinged ? egg.unhingedMessage : egg.message)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                DisclosureGroup("A tiny hint") {
                    Text(egg.discoveryHint)
                        .font(.footnote)
                        .foregroundStyle(palette.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
                .font(.footnote.weight(.medium))
            }
        }
        .padding(17)
        .background(palette.digit, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("collection.\(found ? "discovered" : "locked").\(egg.id)")
    }
}
