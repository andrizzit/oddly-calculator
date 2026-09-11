import Foundation

/// Humor changes the companion copy, never a calculation or its formatting.
public enum PersonalityMode: String, CaseIterable, Codable, Sendable {
    case calm
    case playful
    case unhinged

    public var title: String {
        switch self {
        case .calm: return "Calm"
        case .playful: return "Playful"
        case .unhinged: return "Unhinged"
        }
    }

    public var subtitle: String {
        switch self {
        case .calm: return "Just you and the numbers."
        case .playful: return "A little wit. A few discoveries."
        case .unhinged: return "Same math. More tiny nonsense."
        }
    }
}

/// A collectible with a stable identifier so discoveries can be stored locally.
public struct EasterEgg: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    /// An SF Symbols name. The UI supplies its own accessible label.
    public let symbol: String
    public let message: String
    public let unhingedMessage: String
    public let discoveryHint: String

    public init(id: String, title: String, symbol: String, message: String,
                unhingedMessage: String, discoveryHint: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.message = message
        self.unhingedMessage = unhingedMessage
        self.discoveryHint = discoveryHint
    }
}

public struct PersonalityReaction: Equatable, Sendable {
    public let message: String
    public let egg: EasterEgg?

    public var isDiscovery: Bool { egg != nil }

    public init(message: String, egg: EasterEgg? = nil) {
        self.message = message
        self.egg = egg
    }
}

/// A deterministic, side-effect-free companion. Call only after a successful equals.
/// Persist discovered IDs in the app, and render reactions separately from the answer.
public enum PersonalityEngine {
    public static let catalogue: [EasterEgg] = [
        EasterEgg(
            id: "cosmic-receipt", title: "Cosmic Receipt", symbol: "sparkles",
            message: "The universe sent a number. No instructions.",
            unhingedMessage: "The universe's accounting department has entered the chat.",
            discoveryHint: "Let six meet seven. Try 6 × 7."
        ),
        EasterEgg(
            id: "tiny-pie", title: "Tiny Pie", symbol: "birthday.cake",
            message: "A perfectly sensible amount of imaginary pie.",
            unhingedMessage: "One tiny pie. Several irrational ambitions.",
            discoveryHint: "Just the first taste of pi. Try 3 + 0.14."
        ),
        EasterEgg(
            id: "century-club", title: "Century Club", symbol: "party.popper",
            message: "One hundred. Please accept this invisible ribbon.",
            unhingedMessage: "One hundred! The confetti budget is still imaginary.",
            discoveryHint: "A very round milestone. Try 25 × 4."
        ),
        EasterEgg(
            id: "byte-sized", title: "Byte Sized", symbol: "square.grid.3x3",
            message: "256 possibilities. One very organized byte.",
            unhingedMessage: "A byte has opened its wardrobe. 256 outfits. All binary.",
            discoveryHint: "Double your way to 256. Or try 16 × 16."
        ),
        EasterEgg(
            id: "lost-and-found", title: "Lost & Found", symbol: "magnifyingglass",
            message: "404. Found it, actually.",
            unhingedMessage: "Number found. The search party is eating the snacks anyway.",
            discoveryHint: "A famously missing number. Try 400 + 4."
        ),
        EasterEgg(
            id: "paper-cranes", title: "Paper Cranes", symbol: "bird",
            message: "A thousand. Imagine the paper cranes.",
            unhingedMessage: "A thousand paper cranes have requested more legroom.",
            discoveryHint: "Fold your way to a thousand. Try 250 × 4."
        ),
        EasterEgg(
            id: "taxi-for-cubes", title: "Taxi for Cubes", symbol: "car.side",
            message: "Two pairs of cubes. One surprisingly busy taxi.",
            unhingedMessage: "1729. Four cubes are arguing over the taxi fare.",
            discoveryHint: "A famous taxi number. Try 1728 + 1."
        ),
        EasterEgg(
            id: "mirror-mirror", title: "Mirror, Mirror", symbol: "arrow.left.and.right",
            message: "12321. This number has excellent backward posture.",
            unhingedMessage: "This number walked backward into a mirror and remained employed.",
            discoveryHint: "A number that reads both ways. Try 12320 + 1."
        )
    ]

    /// Passing `previousResult` suppresses chatter when the same answer is repeated.
    /// Calm mode also pauses new discoveries. Known eggs never show their reveal twice.
    public static func reaction(
        forResult result: Decimal,
        expression: String,
        mode: PersonalityMode,
        discoveredEggIDs: Set<String>,
        completedCalculationCount: Int = 1,
        previousResult: Decimal? = nil
    ) -> PersonalityReaction? {
        guard mode != .calm, !result.isNaN, previousResult != result else { return nil }

        if let egg = matchingEgg(for: result), !discoveredEggIDs.contains(egg.id) {
            return PersonalityReaction(
                message: mode == .unhinged ? egg.unhingedMessage : egg.message,
                egg: egg
            )
        }

        let interval = mode == .playful ? 4 : 2
        guard completedCalculationCount > 0,
              completedCalculationCount.isMultiple(of: interval) else { return nil }
        let lines = mode == .playful ? playfulLines : unhingedLines
        // Do not use Swift's randomized Hasher: the same inputs should give the same copy.
        let seed = expression.utf8.reduce(UInt64(5381)) { ($0 &* 33) &+ UInt64($1) }
        return PersonalityReaction(message: lines[Int(seed % UInt64(lines.count))])
    }

    public static func greeting(for mode: PersonalityMode) -> String {
        switch mode {
        case .calm: return "A little room to think."
        case .playful: return "Serious math. Curious little creature."
        case .unhinged: return "The numbers have arrived. Nobody checked their luggage."
        }
    }

    private static func matchingEgg(for result: Decimal) -> EasterEgg? {
        // Explicit decimal values avoid binary floating-point approximation near a trigger.
        let values: [Decimal] = [42, Decimal(314) / 100, 100, 256, 404, 1000, 1729, 12321]
        guard let index = values.firstIndex(of: result) else { return nil }
        return catalogue[index]
    }

    private static let playfulLines = [
        "The numbers have been politely arranged.",
        "A small mystery, neatly solved.",
        "Freshly calculated. Still warm.",
        "A little less guesswork in the world.",
        "All the digits are accounted for.",
        "Arithmetic, with its shoes tied.",
        "A neat little landing.",
        "That answer has settled in nicely."
    ]

    private static let unhingedLines = [
        "A committee of tiny ducks approved this calculation.",
        "The digits have unionized. Excellent working conditions.",
        "Somewhere, an abacus just felt a disturbance.",
        "The decimal point requested a window seat.",
        "Answer delivered by an extremely small forklift.",
        "The numbers are wearing their formal pajamas.",
        "Arithmetic has briefly escaped the stationery cupboard.",
        "A respectable answer with suspiciously good tap shoes."
    ]
}
