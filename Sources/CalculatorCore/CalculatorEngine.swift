import Foundation

public enum CalculatorOperator: String, Codable, CaseIterable, Sendable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"

    public var accessibilityName: String {
        switch self {
        case .add: "Add"
        case .subtract: "Subtract"
        case .multiply: "Multiply"
        case .divide: "Divide"
        }
    }
}

public enum UnaryOperation: String, CaseIterable, Sendable {
    case square, squareRoot, reciprocal
}

public enum CalculatorKey: Equatable, Sendable {
    case digit(Int)
    case decimal
    case operation(CalculatorOperator)
    case equals
    case clear
    case delete
    case toggleSign
    case percent
    case unary(UnaryOperation)
    case pi
}

public enum CalculatorError: Error, Equatable, Sendable {
    case divisionByZero
    case negativeSquareRoot
    case outOfRange
    case invalidNumber

    public var message: String {
        switch self {
        case .divisionByZero: "You can’t divide by zero. Enter a number to start again."
        case .negativeSquareRoot: "A negative number has no real square root. Enter a number to start again."
        case .outOfRange: "That number is outside the calculator’s range. Enter a number to start again."
        case .invalidNumber: "That isn’t a supported number. Enter a number to start again."
        }
    }
}

/// A decimal pocket calculator. Binary operations run in the order entered.
/// The breadcrumb always shows the current operation, never a misleading
/// multi-operator expression that would imply algebraic precedence.
public struct CalculatorEngine: Sendable {
    public private(set) var display = "0"
    public private(set) var expression = ""
    public private(set) var error: CalculatorError?
    public private(set) var pendingOperation: CalculatorOperator?
    public static let maximumEntryDigits = 18

    private var accumulator: Decimal?
    private var replaceEntry = true
    private var awaitingOperand = false
    private var repeatedOperation: CalculatorOperator?
    private var repeatedOperand: Decimal?

    public init() {}

    public var displayValue: Decimal? {
        guard error == nil else { return nil }
        return Self.decimal(display)
    }

    /// Returns a completed calculation only when an operation is evaluated.
    /// This includes standalone scientific operations as well as equals.
    @discardableResult
    public mutating func press(_ key: CalculatorKey) -> CalculationRecord? {
        do {
            switch key {
            case .clear: clear()
            case .delete: delete()
            case .digit(let digit): enter(digit: digit)
            case .decimal: enterDecimal()
            case .toggleSign: toggleSign()
            case .pi:
                if error != nil { clear() }
                if pendingOperation == nil { expression = "" }
                display = "3.1415926535897932384626433832795028842"
                replaceEntry = true
                awaitingOperand = false
                resetRepeat()
            case .operation(let operation): try setOperation(operation)
            case .equals: return try evaluate()
            case .percent: try percent()
            case .unary(let operation): return try apply(operation)
            }
        } catch let failure as CalculatorError {
            fail(failure)
        } catch {
            fail(.outOfRange)
        }
        return nil
    }

    public mutating func clear() {
        display = "0"
        expression = ""
        error = nil
        accumulator = nil
        pendingOperation = nil
        replaceEntry = true
        awaitingOperand = false
        resetRepeat()
    }

    /// Recalls the exact stored decimal, with the next digit starting fresh.
    @discardableResult
    public mutating func recall(_ value: String) -> Bool {
        guard let parsed = Self.decimal(value), !parsed.isNaN else { return false }
        clear()
        display = Self.string(parsed)
        return true
    }

    private mutating func enter(digit: Int) {
        guard (0...9).contains(digit) else { return }
        prepareForEntry()
        if replaceEntry {
            display = String(digit)
            replaceEntry = false
        } else if display == "0" {
            display = String(digit)
        } else if display == "-0" {
            display = digit == 0 ? "-0" : "-\(digit)"
        } else if display.filter(\.isNumber).count < Self.maximumEntryDigits {
            display += String(digit)
        }
        awaitingOperand = false
    }

    private mutating func enterDecimal() {
        prepareForEntry()
        if replaceEntry {
            display = "0."
            replaceEntry = false
        } else if !display.contains(".") {
            display += "."
        }
        awaitingOperand = false
    }

    private mutating func prepareForEntry() {
        if error != nil { clear() }
        if replaceEntry && pendingOperation == nil { expression = "" }
        resetRepeat()
    }

    private mutating func delete() {
        if error != nil { clear(); return }
        resetRepeat()
        if replaceEntry {
            if pendingOperation != nil && awaitingOperand {
                pendingOperation = nil
                accumulator = nil
                awaitingOperand = false
                expression = ""
                // A computed number may use more digits than manual entry.
                // Treat it as a recalled value until the next input action.
                return
            }
            clear()
            return
        }
        display.removeLast()
        if display.isEmpty || display == "-" { display = "0" }
        if pendingOperation == nil { expression = "" }
    }

    private mutating func toggleSign() {
        if error != nil { clear() }
        let remainsComputed = replaceEntry && !awaitingOperand && display != "0"
        if awaitingOperand && pendingOperation != nil {
            display = "-0"
        } else if display.hasPrefix("-") {
            display.removeFirst()
        } else {
            display = "-" + display
        }
        replaceEntry = remainsComputed
        awaitingOperand = false
        if pendingOperation == nil { expression = "" }
        resetRepeat()
    }

    private mutating func setOperation(_ operation: CalculatorOperator) throws {
        guard error == nil, let current = displayValue else { return }
        var value = current
        if let pendingOperation, let accumulator, !awaitingOperand {
            value = try Self.calculate(accumulator, pendingOperation, current)
            display = Self.string(value)
        }
        accumulator = value
        pendingOperation = operation
        expression = "\(Self.string(value)) \(operation.rawValue)"
        replaceEntry = true
        awaitingOperand = true
        resetRepeat()
    }

    private mutating func evaluate() throws -> CalculationRecord? {
        guard error == nil, let current = displayValue else { return nil }
        let left: Decimal
        let right: Decimal
        let operation: CalculatorOperator?
        if let pendingOperation, let accumulator {
            left = accumulator
            right = current
            operation = pendingOperation
        } else if let repeatedOperation, let repeatedOperand {
            left = current
            right = repeatedOperand
            operation = repeatedOperation
        } else {
            left = current
            right = current
            operation = nil
        }

        let result: Decimal
        let completedExpression: String
        if let operation {
            result = try Self.calculate(left, operation, right)
            completedExpression = "\(Self.string(left)) \(operation.rawValue) \(Self.string(right))"
            repeatedOperation = operation
            repeatedOperand = right
        } else {
            result = current
            completedExpression = Self.string(current)
        }
        display = Self.string(result)
        expression = completedExpression + " ="
        pendingOperation = nil
        accumulator = nil
        replaceEntry = true
        awaitingOperand = false
        return CalculationRecord(expression: completedExpression, result: display)
    }

    private mutating func percent() throws {
        guard error == nil, let current = displayValue else { return }
        let fraction = try Self.calculate(current, .divide, 100)
        let value: Decimal
        if let accumulator, pendingOperation == .add || pendingOperation == .subtract {
            value = try Self.calculate(accumulator, .multiply, fraction)
        } else {
            value = fraction
        }
        display = Self.string(value)
        replaceEntry = true
        awaitingOperand = false
        if pendingOperation == nil { expression = "\(Self.string(current))%" }
        resetRepeat()
    }

    private mutating func apply(_ operation: UnaryOperation) throws -> CalculationRecord? {
        guard error == nil, let current = displayValue else { return nil }
        let value: Decimal
        let completedExpression: String
        switch operation {
        case .square:
            value = try Self.calculate(current, .multiply, current)
            completedExpression = "(\(Self.string(current)))²"
        case .squareRoot:
            guard current >= 0 else { throw CalculatorError.negativeSquareRoot }
            value = try Self.squareRoot(current)
            completedExpression = "√(\(Self.string(current)))"
        case .reciprocal:
            value = try Self.calculate(1, .divide, current)
            completedExpression = "1 ÷ \(Self.string(current))"
        }
        display = Self.string(value)
        resetRepeat()
        replaceEntry = true
        awaitingOperand = false
        if pendingOperation == nil {
            expression = completedExpression + " ="
            return CalculationRecord(expression: completedExpression, result: display)
        }
        return nil
    }

    private mutating func resetRepeat() {
        repeatedOperation = nil
        repeatedOperand = nil
    }

    private mutating func fail(_ failure: CalculatorError) {
        error = failure
        display = "Error"
        accumulator = nil
        pendingOperation = nil
        replaceEntry = true
        awaitingOperand = false
        resetRepeat()
    }

    private static func decimal(_ string: String) -> Decimal? {
        guard !string.isEmpty, string != "-" else { return nil }
        // Decimal(string:) accepts numeric prefixes; history/recall must not.
        guard string.range(of: #"^-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$"#, options: .regularExpression) != nil else { return nil }
        return Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func string(_ value: Decimal) -> String {
        if value == 0 { return "0" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private static func calculate(_ left: Decimal, _ operation: CalculatorOperator, _ right: Decimal) throws -> Decimal {
        if operation == .divide && right == 0 { throw CalculatorError.divisionByZero }
        var lhs = left
        var rhs = right
        var result = Decimal()
        let status: Decimal.CalculationError
        switch operation {
        case .add: status = NSDecimalAdd(&result, &lhs, &rhs, .plain)
        case .subtract: status = NSDecimalSubtract(&result, &lhs, &rhs, .plain)
        case .multiply: status = NSDecimalMultiply(&result, &lhs, &rhs, .plain)
        case .divide: status = NSDecimalDivide(&result, &lhs, &rhs, .plain)
        }
        switch status {
        case .noError, .lossOfPrecision:
            guard !result.isNaN else { throw CalculatorError.outOfRange }
            // Some Foundation versions report success after wrapping Decimal's
            // exponent on extreme multiplication. Double spans Decimal's whole
            // representable range and provides an independent magnitude check;
            // it never supplies or rounds the actual arithmetic result.
            if operation == .multiply || operation == .divide {
                let lhsMagnitude = NSDecimalNumber(decimal: left).doubleValue
                let rhsMagnitude = NSDecimalNumber(decimal: right).doubleValue
                let expected = operation == .multiply ? lhsMagnitude * rhsMagnitude : lhsMagnitude / rhsMagnitude
                let actual = NSDecimalNumber(decimal: result).doubleValue
                guard expected.isFinite, actual.isFinite else { throw CalculatorError.outOfRange }
                if expected == 0 {
                    guard result == 0 else { throw CalculatorError.outOfRange }
                } else {
                    guard abs((actual - expected) / expected) < 1e-12 else { throw CalculatorError.outOfRange }
                }
            }
            return result
        case .divideByZero: throw CalculatorError.divisionByZero
        case .overflow, .underflow: throw CalculatorError.outOfRange
        @unknown default: throw CalculatorError.outOfRange
        }
    }

    private static func squareRoot(_ value: Decimal) throws -> Decimal {
        if value == 0 { return 0 }
        // A floating-point seed only accelerates convergence; Newton's method
        // then works entirely in Decimal at the engine's native precision.
        let seed = NSDecimalNumber(decimal: value).doubleValue.squareRoot()
        guard seed.isFinite, seed > 0 else { throw CalculatorError.outOfRange }
        guard var estimate = Decimal(string: String(seed), locale: Locale(identifier: "en_US_POSIX")) else {
            throw CalculatorError.outOfRange
        }
        var previous: Decimal?
        for _ in 0..<24 {
            let quotient = try calculate(value, .divide, estimate)
            let sum = try calculate(estimate, .add, quotient)
            let next = try calculate(sum, .divide, 2)
            if next == estimate || next == previous { return next }
            previous = estimate
            estimate = next
        }
        return estimate
    }
}
