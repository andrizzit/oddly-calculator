import Foundation
import Testing
@testable import CalculatorCore

private func input(_ number: String, into engine: inout CalculatorEngine) {
    for character in number {
        switch character {
        case "-": engine.press(.toggleSign)
        case ".": engine.press(.decimal)
        default:
            if let digit = character.wholeNumberValue { engine.press(.digit(digit)) }
        }
    }
}

@Suite("Independent adversarial arithmetic and state QA")
struct AdversarialArithmeticTests {
    @Test func signedIntegerOperationsAgreeWithIndependentReference() {
        for lhs in [-999, -23, -1, 0, 1, 17, 999] {
            for rhs in [-91, -3, -1, 0, 1, 7, 91] {
                for operation in [CalculatorOperator.add, .subtract, .multiply] {
                    var engine = CalculatorEngine()
                    input(String(lhs), into: &engine)
                    engine.press(.operation(operation))
                    input(String(rhs), into: &engine)
                    let record = engine.press(.equals)
                    let expected: Int
                    switch operation {
                    case .add: expected = lhs + rhs
                    case .subtract: expected = lhs - rhs
                    case .multiply: expected = lhs * rhs
                    case .divide: preconditionFailure("Not part of this integer oracle")
                    }
                    #expect(engine.displayValue == Decimal(expected), "\(lhs) \(operation.rawValue) \(rhs)")
                    #expect(record?.result == String(expected))
                    #expect(engine.error == nil)
                }
            }
        }
    }

    @Test func chainedIntermediateDecimalPrecisionIsNotDisplayRounded() {
        var engine = CalculatorEngine()
        input("1", into: &engine)
        engine.press(.operation(.divide))
        input("3", into: &engine)
        engine.press(.equals)
        #expect(engine.display.count >= 30)
        engine.press(.operation(.multiply))
        input("3", into: &engine)
        engine.press(.equals)
        let error = abs((engine.displayValue ?? 0) - 1)
        #expect(error < Decimal(string: "1e-30")!)
    }

    @Test func mixedOperationsHaveOnlyTheActualEvaluatedBreadcrumb() {
        var engine = CalculatorEngine()
        input("2", into: &engine)
        engine.press(.operation(.add))
        input("3", into: &engine)
        engine.press(.operation(.multiply))
        #expect(engine.expression == "5 ×")
        input("4", into: &engine)
        let record = engine.press(.equals)
        #expect(engine.display == "20")
        #expect(engine.expression == "5 × 4 =")
        #expect(record?.expression == "5 × 4")
        #expect(record?.result == "20")
    }

    @Test func percentRepeatsItsResolvedOperand() {
        var engine = CalculatorEngine()
        input("200", into: &engine)
        engine.press(.operation(.add))
        input("10", into: &engine)
        engine.press(.percent)
        let first = engine.press(.equals)
        #expect(first?.expression == "200 + 20")
        #expect(engine.display == "220")
        let repeated = engine.press(.equals)
        #expect(repeated?.expression == "220 + 20")
        #expect(engine.display == "240")
    }

    @Test func negativeAndFractionalPercentOperands() {
        var engine = CalculatorEngine()
        input("80", into: &engine)
        engine.press(.operation(.subtract))
        input("12.5", into: &engine)
        engine.press(.percent)
        engine.press(.equals)
        #expect(engine.display == "70")
        engine.clear()
        input("200", into: &engine)
        engine.press(.operation(.add))
        input("-10", into: &engine)
        engine.press(.percent)
        engine.press(.equals)
        #expect(engine.display == "180")
    }

    @Test func newDecimalAfterEqualsStartsFreshAndClearsRepeat() {
        var engine = CalculatorEngine()
        input("9", into: &engine)
        engine.press(.operation(.add))
        input("1", into: &engine)
        engine.press(.equals)
        engine.press(.decimal)
        input("5", into: &engine)
        #expect(engine.display == "0.5")
        #expect(engine.expression.isEmpty)
        engine.press(.equals)
        engine.press(.equals)
        #expect(engine.display == "0.5")
    }

    @Test func deletingRightOperandKeepsPendingLeftOperand() {
        var engine = CalculatorEngine()
        input("12", into: &engine)
        engine.press(.operation(.subtract))
        input("-34", into: &engine)
        engine.press(.delete)
        #expect(engine.display == "-3")
        #expect(engine.expression == "12 −")
        engine.press(.delete)
        #expect(engine.display == "0")
        input("2", into: &engine)
        engine.press(.equals)
        #expect(engine.display == "10")
    }

    @Test func clearingAfterAnErrorRemovesPendingAndRepeatedOperations() {
        var engine = CalculatorEngine()
        input("2", into: &engine)
        engine.press(.operation(.add))
        input("3", into: &engine)
        engine.press(.equals)
        engine.press(.operation(.divide))
        input("0", into: &engine)
        #expect(engine.press(.equals) == nil)
        #expect(engine.error == .divisionByZero)
        #expect(engine.press(.equals) == nil)
        #expect(engine.press(.unary(.square)) == nil)
        engine.press(.clear)
        #expect(engine.expression.isEmpty)
        #expect(engine.pendingOperation == nil)
        input("6", into: &engine)
        engine.press(.equals)
        #expect(engine.display == "6")
    }

    @Test(arguments: [CalculatorKey.digit(7), .decimal, .pi, .toggleSign, .delete, .clear])
    func errorsRecoverWithSupportedEntryActions(action: CalculatorKey) {
        var engine = CalculatorEngine()
        engine.press(.unary(.reciprocal))
        #expect(engine.error == .divisionByZero)
        engine.press(action)
        #expect(engine.error == nil)
        #expect(engine.displayValue != nil)
        #expect(engine.pendingOperation == nil)
    }

    @Test func reciprocalWithinPendingCalculationUsesCurrentOperand() {
        var engine = CalculatorEngine()
        input("4", into: &engine)
        engine.press(.operation(.add))
        input("8", into: &engine)
        #expect(engine.press(.unary(.reciprocal)) == nil)
        #expect(engine.expression == "4 +")
        let record = engine.press(.equals)
        #expect(record?.expression == "4 + 0.125")
        #expect(record?.result == "4.125")
    }

    @Test func piRightOperandCommitsBeforeNextOperator() {
        var engine = CalculatorEngine()
        input("2", into: &engine)
        engine.press(.operation(.multiply))
        engine.press(.pi)
        engine.press(.operation(.add))
        #expect((engine.displayValue ?? 0) > 6)
        #expect((engine.displayValue ?? 100) < 7)
        input("1", into: &engine)
        engine.press(.equals)
        #expect((engine.displayValue ?? 0) > 7)
        #expect((engine.displayValue ?? 100) < 8)
    }

    @Test func signedPiDoesNotBlockTheNextNumberEntry() {
        var engine = CalculatorEngine()
        engine.press(.pi)
        engine.press(.toggleSign)
        #expect((engine.displayValue ?? 0) < -3)
        engine.press(.digit(7))
        #expect(engine.display == "7")
        engine.press(.equals)
        #expect(engine.display == "7")
    }

    @Test func typingAfterPercentReplacesTheTransformedRightOperand() {
        var engine = CalculatorEngine()
        input("200", into: &engine)
        engine.press(.operation(.add))
        input("10", into: &engine)
        engine.press(.percent)
        #expect(engine.display == "20")
        input("2", into: &engine)
        engine.press(.equals)
        #expect(engine.display == "202")
    }

    @Test func typingAfterScientificFunctionReplacesTheTransformedRightOperand() {
        var engine = CalculatorEngine()
        input("2", into: &engine)
        engine.press(.operation(.add))
        input("9", into: &engine)
        engine.press(.unary(.squareRoot))
        #expect(engine.display == "3")
        input("4", into: &engine)
        engine.press(.equals)
        #expect(engine.display == "6")
    }

    @Test func squareRootOfPerfectDecimalSquaresIsExact() {
        for (value, expected) in [("0", "0"), ("0.0004", "0.02"), ("15241578750190521", "123456789"), ("1e100", "1e50"), ("1e-100", "1e-50")] {
            var engine = CalculatorEngine()
            let recalled = engine.recall(value)
            #expect(recalled)
            let record = engine.press(.unary(.squareRoot))
            #expect(engine.displayValue == Decimal(string: expected), "√(\(value))")
            #expect(record != nil)
            #expect(engine.error == nil)
        }
    }

    @Test func roundingNearRepresentableBoundaryStaysFinite() {
        var engine = CalculatorEngine()
        let recalled = engine.recall("99999999999999999999999999999999999999")
        #expect(recalled)
        engine.press(.operation(.add))
        input("1", into: &engine)
        let record = engine.press(.equals)
        #expect(engine.displayValue == Decimal(string: "1e38"))
        #expect(record?.result != "NaN")
        #expect(engine.error == nil)
    }

    @Test func underflowIsExplicitAndNeverSavedAsZero() {
        var engine = CalculatorEngine()
        let recalled = engine.recall("1e-100")
        #expect(recalled)
        #expect(engine.press(.unary(.square)) == nil)
        #expect(engine.error == .outOfRange)
        #expect(engine.display == "Error")
        #expect(engine.displayValue == nil)
    }

    @Test func repeatedSquaringFromOrdinaryKeyEntryCannotWrapExponent() {
        var engine = CalculatorEngine()
        input("10000000000", into: &engine)
        engine.press(.unary(.reciprocal))
        for _ in 0..<3 { engine.press(.unary(.square)) }
        #expect(engine.displayValue == Decimal(string: "1e-80"))
        #expect(engine.press(.unary(.square)) == nil)
        #expect(engine.error == .outOfRange)
        engine.press(.digit(3))
        engine.press(.unary(.square))
        #expect(engine.display == "9")
    }

    @Test func smallestDecimalProductCannotBecomeAstronomicallyLarge() {
        var engine = CalculatorEngine()
        let recalled = engine.recall("1e-128")
        #expect(recalled)
        engine.press(.operation(.multiply))
        input("0.1", into: &engine)
        #expect(engine.press(.equals) == nil)
        #expect(engine.error == .outOfRange)
    }

    @Test func tinyDivisionIsEitherAccurateOrAnExplicitRangeError() {
        var engine = CalculatorEngine()
        let recalled = engine.recall("1e-80")
        #expect(recalled)
        engine.press(.operation(.divide))
        input("10", into: &engine)
        engine.press(.equals)
        #expect(engine.displayValue == Decimal(string: "1e-81"))
        #expect(engine.error == nil)

        // Foundation division can exhaust its intermediate exponent range
        // before the result reaches Decimal's storage bound. It must report
        // that limit explicitly; a wrapped or zero answer is never acceptable.
        engine.recall("1e-100")
        engine.press(.operation(.divide))
        input("10", into: &engine)
        let extremeRecord = engine.press(.equals)
        if let value = engine.displayValue {
            #expect(value == Decimal(string: "1e-101"))
            #expect(extremeRecord != nil)
        } else {
            #expect(engine.error == .outOfRange)
            #expect(extremeRecord == nil)
        }

        engine.clear()
        let smallestRecalled = engine.recall("1e-128")
        #expect(smallestRecalled)
        engine.press(.operation(.divide))
        input("10", into: &engine)
        #expect(engine.press(.equals) == nil)
        #expect(engine.error == .outOfRange)
        #expect(engine.displayValue == nil)
    }

    @Test func multiplicationAndAdditionOverflowCannotBecomeValidHistory() {
        for operation in [CalculatorOperator.multiply, .add] {
            var engine = CalculatorEngine()
            let maximum = NSDecimalNumber(decimal: .greatestFiniteMagnitude).stringValue
            let recalled = engine.recall(maximum)
            #expect(recalled)
            engine.press(.operation(operation))
            if operation == .multiply { input("2", into: &engine) }
            // Omitted right operand in addition doubles the maximum.
            #expect(engine.press(.equals) == nil)
            #expect(engine.error == .outOfRange)
            #expect(engine.displayValue == nil)
        }
    }

    @Test(arguments: ["42garbage", " 42", "42 ", "NaN", "Infinity", "--3", "1,234", "1.2.3", "1e", "", "1e999", "1e-999"])
    func invalidRecallDoesNotDestroyExistingOperation(value: String) {
        var engine = CalculatorEngine()
        input("7", into: &engine)
        engine.press(.operation(.add))
        let recalled = engine.recall(value)
        #expect(!recalled)
        #expect(engine.display == "7")
        #expect(engine.expression == "7 +")
        input("2", into: &engine)
        engine.press(.equals)
        #expect(engine.display == "9")
    }
}

@Suite("Independent local history QA")
struct AdversarialHistoryTests {
    @Test func decodingEnforcesTheSameBoundAsAppending() throws {
        let records = (0..<150).map { CalculationRecord(expression: "\($0)", result: "\($0)") }
        let payload = try JSONEncoder().encode(["records": records])
        let restored = try JSONDecoder().decode(CalculationHistory.self, from: payload)
        #expect(restored.records.count == 100)
        #expect(restored.records.first == records.first)
        #expect(restored.records.last == records[99])
    }

    @Test func persistedRecordsKeepIdentityDateAndCanonicalPrecision() throws {
        let expected = CalculationRecord(date: Date(timeIntervalSince1970: 1234567890), expression: "1 ÷ 7", result: "0.14285714285714285714285714285714285714")
        let original = CalculationHistory(records: [expected])
        let restored = try JSONDecoder().decode(CalculationHistory.self, from: JSONEncoder().encode(original))
        #expect(restored == original)
        var engine = CalculatorEngine()
        let recalled = engine.recall(restored.records[0].result)
        #expect(recalled)
        #expect(engine.display == expected.result)
        engine.press(.digit(8))
        #expect(engine.display == "8")
    }

    @Test func corruptStorageSignalsFailureInsteadOfPretendingToBeEmpty() {
        let malformed = Data(#"{"records":[{"expression":"1 + 1","result":"2"}]}"#.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(CalculationHistory.self, from: malformed)
        }
    }
}

@Suite("Independent personality and discovery QA")
struct AdversarialPersonalityTests {
    private let fixtures: [(String, String)] = [
        ("42", "cosmic-receipt"), ("3.14", "tiny-pie"), ("100", "century-club"),
        ("256", "byte-sized"), ("404", "lost-and-found"), ("1000", "paper-cranes"),
        ("1729", "taxi-for-cubes"), ("12321", "mirror-mirror")
    ]

    @Test func allDocumentedEggsHaveExactPositiveTriggers() {
        for (value, identifier) in fixtures {
            let decimal = Decimal(string: value)!
            for mode in [PersonalityMode.playful, .unhinged] {
                let reaction = PersonalityEngine.reaction(forResult: decimal, expression: value, mode: mode, discoveredEggIDs: [])
                #expect(reaction?.egg?.id == identifier)
                #expect(reaction?.isDiscovery == true)
                #expect(reaction?.message.isEmpty == false)
            }
            for nearMiss in [decimal + Decimal(string: "0.00000001")!, decimal - Decimal(string: "0.00000001")!, -decimal] {
                #expect(PersonalityEngine.reaction(forResult: nearMiss, expression: value, mode: .playful, discoveredEggIDs: []) == nil)
            }
        }
        #expect(Set(PersonalityEngine.catalogue.map(\.id)).count == 8)
    }

    @Test func calmPausesAllDiscoveriesAndOrdinaryCopy() {
        for (value, _) in fixtures + [("7", "ordinary")] {
            for count in [1, 2, 4, 100] {
                #expect(PersonalityEngine.reaction(forResult: Decimal(string: value)!, expression: value, mode: .calm, discoveredEggIDs: [], completedCalculationCount: count) == nil)
            }
        }
    }

    @Test func discoveredIDsRoundTripAndPreventRepeatedReveal() throws {
        let ids = Set(fixtures.map(\.1))
        let restored = try JSONDecoder().decode(Set<String>.self, from: JSONEncoder().encode(ids))
        #expect(restored == ids)
        for (value, _) in fixtures {
            #expect(PersonalityEngine.reaction(forResult: Decimal(string: value)!, expression: value, mode: .playful, discoveredEggIDs: restored) == nil)
            let occasionalCopy = PersonalityEngine.reaction(forResult: Decimal(string: value)!, expression: value, mode: .playful, discoveredEggIDs: restored, completedCalculationCount: 4)
            #expect(occasionalCopy?.egg == nil)
        }
    }

    @Test func repeatResultSuppressesEvenAnOtherwiseEligibleDiscovery() {
        for (value, _) in fixtures {
            let number = Decimal(string: value)!
            #expect(PersonalityEngine.reaction(forResult: number, expression: value, mode: .unhinged, discoveredEggIDs: [], completedCalculationCount: 4, previousResult: number) == nil)
        }
    }

    @Test func ordinaryCopyHasDeterministicLimitedCadence() {
        for count in 1...16 {
            let playful = PersonalityEngine.reaction(forResult: 7, expression: "3 + 4", mode: .playful, discoveredEggIDs: [], completedCalculationCount: count)
            let unhinged = PersonalityEngine.reaction(forResult: 7, expression: "3 + 4", mode: .unhinged, discoveredEggIDs: [], completedCalculationCount: count)
            #expect((playful != nil) == count.isMultiple(of: 4))
            #expect((unhinged != nil) == count.isMultiple(of: 2))
            #expect(playful?.egg == nil)
            #expect(unhinged?.egg == nil)
            #expect(playful == PersonalityEngine.reaction(forResult: 7, expression: "3 + 4", mode: .playful, discoveredEggIDs: [], completedCalculationCount: count))
        }
        #expect(PersonalityEngine.reaction(forResult: 7, expression: "7", mode: .unhinged, discoveredEggIDs: [], completedCalculationCount: 0) == nil)
        #expect(PersonalityEngine.reaction(forResult: Decimal.nan, expression: "bad", mode: .unhinged, discoveredEggIDs: [], completedCalculationCount: 4) == nil)
    }
}
