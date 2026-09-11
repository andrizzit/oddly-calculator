import SwiftUI
import CalculatorCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppearanceChoice: String, CaseIterable, Identifiable {
    case system, paper, midnight
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .paper: .light
        case .midnight: .dark
        }
    }
}

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published private(set) var engine = CalculatorEngine()
    @Published private(set) var history: CalculationHistory
    @Published private(set) var discoveredEggIDs: Set<String>
    @Published private(set) var reaction: PersonalityReaction?
    @Published private(set) var celebrationCount = 0
    @Published private(set) var notice: String?
    @Published private(set) var historyRecoveryNotice: String?
    @Published var personality: PersonalityMode {
        didSet {
            defaults.set(personality.rawValue, forKey: "personality")
            reaction = nil
            previousResult = nil
        }
    }
    @Published var appearance: AppearanceChoice {
        didSet { defaults.set(appearance.rawValue, forKey: "appearance") }
    }
    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }
    @Published var showScience: Bool {
        didSet { defaults.set(showScience, forKey: "showScience") }
    }

    private let defaults: UserDefaults
    private var completedCalculationCount: Int
    private var previousResult: Decimal?
    private var noticeTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        personality = PersonalityMode(rawValue: defaults.string(forKey: "personality") ?? "") ?? .playful
        appearance = AppearanceChoice(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .paper
        hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        showScience = defaults.bool(forKey: "showScience")
        completedCalculationCount = defaults.integer(forKey: "calculationCount")
        let knownIDs = Set(PersonalityEngine.catalogue.map(\.id))
        discoveredEggIDs = Set(defaults.stringArray(forKey: "discoveredEggIDs") ?? []).intersection(knownIDs)
        if let data = defaults.data(forKey: "history") {
            do {
                history = try JSONDecoder().decode(CalculationHistory.self, from: data)
            } catch {
                history = CalculationHistory()
                if defaults.data(forKey: "historyRecoveryBackup") == nil {
                    defaults.set(data, forKey: "historyRecoveryBackup")
                }
            }
        } else {
            history = CalculationHistory()
        }
        historyRecoveryNotice = defaults.data(forKey: "historyRecoveryBackup") == nil ? nil :
            "Some saved history couldn’t be read. A recovery copy is preserved on this device until you clear history."
    }

    var companionMessage: String {
        if let error = engine.error { return error.message }
        if let notice { return notice }
        return reaction?.message ?? PersonalityEngine.greeting(for: personality)
    }

    /// Compact notation is presentation only. History, copy and accessibility
    /// retain all available Decimal digits.
    var formattedDisplay: String {
        guard engine.display.count > 18, let value = engine.displayValue else {
            return engine.display.replacingOccurrences(of: "-", with: "−")
        }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .scientific
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 12
        formatter.exponentSymbol = "e"
        return (formatter.string(from: NSDecimalNumber(decimal: value)) ?? engine.display)
            .replacingOccurrences(of: "-", with: "−")
    }

    func press(_ key: CalculatorKey) {
        noticeTask?.cancel()
        notice = nil
        if key == .clear { reaction = nil }
        let record = engine.press(key)
        if let record {
            history.append(record)
            saveHistory()
            if key == .equals, let result = engine.displayValue {
                completedCalculationCount += 1
                defaults.set(completedCalculationCount, forKey: "calculationCount")
                reaction = PersonalityEngine.reaction(
                    forResult: result,
                    expression: record.expression,
                    mode: personality,
                    discoveredEggIDs: discoveredEggIDs,
                    completedCalculationCount: completedCalculationCount,
                    previousResult: previousResult
                )
                if let egg = reaction?.egg {
                    discoveredEggIDs.insert(egg.id)
                    defaults.set(discoveredEggIDs.sorted(), forKey: "discoveredEggIDs")
                    celebrationCount += 1
                }
                previousResult = result
            } else {
                reaction = nil
            }
            announceResult()
        }
        if engine.error != nil {
            reaction = nil
            announceResult()
        }
        performHaptic(isResult: record != nil, isError: engine.error != nil)
    }

    func recall(_ record: CalculationRecord) {
        if engine.recall(record.result) {
            reaction = nil
            showNotice("Recalled from history.")
        }
    }

    func copyResult(_ value: String? = nil) {
        let text = value ?? engine.display
        guard text != "Error" else { return }
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        showNotice("Copied, with every available digit.")
    }

    func clearHistory() {
        history.clear()
        defaults.removeObject(forKey: "history")
        defaults.removeObject(forKey: "historyRecoveryBackup")
        historyRecoveryNotice = nil
    }

    func resetDiscoveries() {
        discoveredEggIDs.removeAll()
        defaults.removeObject(forKey: "discoveredEggIDs")
        reaction = nil
        previousResult = nil
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: "history")
    }

    private func showNotice(_ text: String) {
        noticeTask?.cancel()
        notice = text
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            self?.notice = nil
        }
    }

    private func announceResult() {
        #if canImport(UIKit)
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: engine.error?.message ?? "Result, \(engine.display)")
        #endif
    }

    private func performHaptic(isResult: Bool, isError: Bool) {
        #if canImport(UIKit)
        guard hapticsEnabled else { return }
        if isError {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else if isResult {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
        } else {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif
    }
}
