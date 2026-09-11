import Foundation
import Testing
@testable import CalculatorCore

private func enter(_ number: String, into engine: inout CalculatorEngine) {
    for character in number {
        if let digit = character.wholeNumberValue {
            engine.press(.digit(digit))
        } else if character == "." {
            engine.press(.decimal)
        } else if character == "-" {
            engine.press(.toggleSign)
        }
    }
}

private func calculate(_ lhs: String, _ operation: CalculatorOperator, _ rhs: String) -> CalculatorEngine {
    var engine = CalculatorEngine()
    enter(lhs, into: &engine)
    engine.press(.operation(operation))
    enter(rhs, into: &engine)
    engine.press(.equals)
    return engine
}

@Test func decimalArithmeticIsExact() {
    #expect(calculate("0.1", .add, "0.2").display == "0.3")
    #expect(calculate("0.3", .subtract, "0.1").display == "0.2")
    #expect(calculate("19.99", .multiply, "3").display == "59.97")
    #expect(calculate("1", .divide, "8").display == "0.125")
    #expect(calculate("999999999999999999", .add, "1").display == "1000000000000000000")
}

@Test func sequentialOperationsHaveHonestBreadcrumbs() {
    var engine = CalculatorEngine()
    enter("2", into: &engine)
    engine.press(.operation(.add))
    enter("3", into: &engine)
    engine.press(.operation(.multiply))
    #expect(engine.display == "5")
    #expect(engine.expression == "5 ×")
    enter("4", into: &engine)
    let record = engine.press(.equals)
    #expect(engine.display == "20")
    #expect(record?.expression == "5 × 4")
}

@Test func replacingPendingOperatorDoesNotCalculate() {
    var engine = CalculatorEngine()
    enter("8", into: &engine)
    engine.press(.operation(.add))
    engine.press(.operation(.multiply))
    enter("3", into: &engine)
    engine.press(.equals)
    #expect(engine.display == "24")
}

@Test func repeatEqualsReusesLastOperand() {
    var engine = calculate("5", .add, "3")
    engine.press(.equals)
    #expect(engine.display == "11")
    engine.press(.equals)
    #expect(engine.display == "14")
    enter("2", into: &engine)
    engine.press(.equals)
    #expect(engine.display == "2")
}

@Test func equalsWithOmittedOperandUsesDisplayedValue() {
    var engine = CalculatorEngine()
    enter("7", into: &engine)
    engine.press(.operation(.multiply))
    engine.press(.equals)
    #expect(engine.display == "49")
    engine.press(.equals)
    #expect(engine.display == "343")
}

@Test(arguments: [(CalculatorOperator.add, "220"), (.subtract, "180"), (.multiply, "20"), (.divide, "2000")])
func contextualPercent(operation: CalculatorOperator, expected: String) {
    var engine = CalculatorEngine()
    enter("200", into: &engine)
    engine.press(.operation(operation))
    enter("10", into: &engine)
    engine.press(.percent)
    engine.press(.equals)
    #expect(engine.display == expected)
}

@Test func standalonePercentAndNegativeValues() {
    var engine = CalculatorEngine()
    enter("10", into: &engine)
    engine.press(.percent)
    #expect(engine.display == "0.1")
    #expect(calculate("-2", .multiply, "-4").display == "8")
    var signed = CalculatorEngine()
    enter("5", into: &signed)
    signed.press(.operation(.add))
    signed.press(.toggleSign)
    enter("3", into: &signed)
    signed.press(.equals)
    #expect(signed.display == "2")
}

@Test func inputHasSingleDecimalPointAndCanBeEdited() {
    var engine = CalculatorEngine()
    engine.press(.decimal)
    engine.press(.decimal)
    enter("05", into: &engine)
    #expect(engine.display == "0.05")
    engine.press(.delete)
    #expect(engine.display == "0.0")
    engine.press(.delete)
    engine.press(.delete)
    engine.press(.delete)
    #expect(engine.display == "0")
    enter("1234567890123456789", into: &engine)
    #expect(engine.display == "123456789012345678")
}

@Test func backspaceCancelsPendingOperatorAndClearResetsRepeat() {
    var engine = CalculatorEngine()
    enter("12", into: &engine)
    engine.press(.operation(.add))
    engine.press(.delete)
    #expect(engine.pendingOperation == nil)
    #expect(engine.display == "12")
    enter("7", into: &engine)
    #expect(engine.display == "7")
    engine.press(.operation(.multiply))
    enter("2", into: &engine)
    engine.press(.equals)
    engine.press(.clear)
    engine.press(.equals)
    #expect(engine.display == "0")
}

@Test func divisionByZeroDoesNotCreateHistoryAndRecoversOnInput() {
    var engine = CalculatorEngine()
    enter("9", into: &engine)
    engine.press(.operation(.divide))
    enter("0", into: &engine)
    #expect(engine.press(.equals) == nil)
    #expect(engine.error == .divisionByZero)
    #expect(engine.displayValue == nil)
    engine.press(.digit(4))
    #expect(engine.display == "4")
    #expect(engine.error == nil)
    engine.press(.operation(.add))
    enter("2", into: &engine)
    engine.press(.equals)
    #expect(engine.display == "6")
}

@Test func scientificFunctionsAndDomainErrors() {
    var engine = CalculatorEngine()
    enter("81", into: &engine)
    #expect(engine.press(.unary(.squareRoot))?.result == "9")
    engine.press(.unary(.square))
    #expect(engine.display == "81")
    engine.clear()
    enter("8", into: &engine)
    engine.press(.unary(.reciprocal))
    #expect(engine.display == "0.125")
    engine.clear()
    enter("-1", into: &engine)
    #expect(engine.press(.unary(.squareRoot)) == nil)
    #expect(engine.error == .negativeSquareRoot)
    engine.press(.delete)
    #expect(engine.display == "0")
    #expect(engine.error == nil)
}

@Test func squareRootConvergesAndKeepsSmallValues() {
    var engine = CalculatorEngine()
    enter("2", into: &engine)
    engine.press(.unary(.squareRoot))
    let root = NSDecimalNumber(decimal: engine.displayValue ?? 0).doubleValue
    #expect(abs(root - 2.0.squareRoot()) < 1e-15)
    engine.recall("1e-100")
    engine.press(.unary(.squareRoot))
    #expect(engine.displayValue == Decimal(string: "1e-50"))
}

@Test func scientificOperandParticipatesInChaining() {
    var engine = CalculatorEngine()
    enter("2", into: &engine)
    engine.press(.operation(.add))
    enter("9", into: &engine)
    engine.press(.unary(.squareRoot))
    engine.press(.operation(.multiply))
    enter("4", into: &engine)
    engine.press(.equals)
    #expect(engine.display == "20")
    engine.clear()
    enter("2", into: &engine)
    engine.press(.operation(.multiply))
    engine.press(.pi)
    engine.press(.operation(.add))
    #expect((engine.displayValue ?? 0) > 6)
    #expect((engine.displayValue ?? 100) < 7)
}

@Test func recallValidatesWholeNumberAndPreservesPrecision() {
    var engine = CalculatorEngine()
    let malformed = engine.recall("42garbage")
    let nan = engine.recall("NaN")
    let infinity = engine.recall("inf")
    let empty = engine.recall("")
    let precise = engine.recall("0.12345678901234567890123456789012345678")
    #expect(!malformed)
    #expect(!nan)
    #expect(!infinity)
    #expect(!empty)
    #expect(precise)
    #expect(engine.display == "0.12345678901234567890123456789012345678")
    engine.press(.digit(7))
    #expect(engine.display == "7")
}

@Test func arithmeticOverflowIsRecoverable() {
    var engine = CalculatorEngine()
    let recalled = engine.recall("1e100")
    #expect(recalled)
    engine.press(.unary(.square))
    #expect(engine.error == .outOfRange)
    engine.press(.decimal)
    #expect(engine.display == "0.")
    #expect(engine.error == nil)
}

@Test func historyIsBoundedAndRoundTrips() throws {
    var history = CalculationHistory()
    for index in 0..<125 {
        history.append(CalculationRecord(expression: "\(index) + 1", result: "\(index + 1)"))
    }
    #expect(history.records.count == 100)
    #expect(history.records.first?.result == "125")
    #expect(history.records.last?.result == "26")
    let data = try JSONEncoder().encode(history)
    #expect(try JSONDecoder().decode(CalculationHistory.self, from: data) == history)
    history.clear()
    #expect(history.records.isEmpty)
}

@Test func digitsReplaceTransformedOperandsInsteadOfAppending() {
    var engine = CalculatorEngine()
    engine.press(.pi)
    engine.press(.toggleSign)
    engine.press(.digit(5))
    #expect(engine.display == "5")

    engine.clear()
    enter("200", into: &engine)
    engine.press(.operation(.add))
    enter("10", into: &engine)
    engine.press(.percent)
    engine.press(.digit(2))
    engine.press(.equals)
    #expect(engine.display == "202")

    engine.clear()
    enter("2", into: &engine)
    engine.press(.operation(.add))
    enter("9", into: &engine)
    engine.press(.unary(.squareRoot))
    engine.press(.digit(4))
    engine.press(.equals)
    #expect(engine.display == "6")
}
