import Foundation
import CalculatorCore

/// Supplemental macOS execution of the actual application coordinator.
/// The iOS UI suite separately verifies persistence across app launches.
@main
struct ModelChecks {
    enum Failure: Error { case assertionsFailed }

    @MainActor
    static func main() throws {
        let domain = "com.oddly.qa.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        var count = 0
        var failures: [String] = []
        func check(_ condition: Bool, _ explanation: String) {
            count += 1
            if !condition { failures.append(explanation) }
        }

        let corrupt = Data("corrupt history fixture".utf8)
        defaults.set(corrupt, forKey: "history")
        defaults.set("calm", forKey: "personality")
        let model = CalculatorViewModel(defaults: defaults)
        check(model.history.records.isEmpty, "Malformed history must not create records")
        check(model.historyRecoveryNotice != nil, "Malformed history needs a recovery explanation")
        check(defaults.data(forKey: "historyRecoveryBackup") == corrupt, "Original malformed bytes must be preserved")
        model.press(.digit(4))
        model.press(.digit(2))
        model.press(.equals)
        check(model.engine.display == "42", "Calculations must continue after malformed history")
        check(model.discoveredEggIDs.isEmpty, "Calm must pause discovery")
        check(defaults.data(forKey: "historyRecoveryBackup") == corrupt, "New history must not destroy the backup")

        model.personality = .playful
        model.press(.equals)
        check(model.discoveredEggIDs == ["cosmic-receipt"], "Leaving Calm must allow discovery of the same result")
        model.hapticsEnabled = false
        let reopened = CalculatorViewModel(defaults: defaults)
        check(reopened.history.records.count == 2, "Coordinator must restore saved calculations")
        check(reopened.discoveredEggIDs == ["cosmic-receipt"], "Coordinator must restore discoveries")
        check(reopened.personality == .playful, "Coordinator must restore personality")
        check(!reopened.hapticsEnabled, "Coordinator must restore haptics preference")
        check(reopened.historyRecoveryNotice != nil, "Recovery warning must survive coordinator restoration")
        reopened.clearHistory()
        let cleared = CalculatorViewModel(defaults: defaults)
        check(cleared.history.records.isEmpty, "Explicit clear must remove history")
        check(cleared.historyRecoveryNotice == nil, "Explicit clear must dismiss the recovery notice")
        check(defaults.data(forKey: "historyRecoveryBackup") == nil, "Explicit clear must remove backup bytes")
        check(cleared.discoveredEggIDs == ["cosmic-receipt"], "Clearing history must preserve discoveries")
        check(cleared.personality == .playful, "Clearing history must preserve personality")
        check(!cleared.hapticsEnabled, "Clearing history must preserve haptics preference")
        if !failures.isEmpty {
            for failure in failures { print("FAIL: \(failure)") }
            throw Failure.assertionsFailed
        }
        print("CalculatorViewModel: \(count) coordinator assertions passed (macOS supplemental QA).")
    }
}
