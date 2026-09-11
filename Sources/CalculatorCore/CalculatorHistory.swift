import Foundation

public struct CalculationRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let expression: String
    public let result: String

    public init(id: UUID = UUID(), date: Date = Date(), expression: String, result: String) {
        self.id = id
        self.date = date
        self.expression = expression
        self.result = result
    }
}

/// Most-recent-first, bounded history. Encoded locally by the app; no account,
/// network access, analytics, or external storage is involved.
public struct CalculationHistory: Codable, Equatable, Sendable {
    public static let maximumCount = 100
    public private(set) var records: [CalculationRecord]

    public init(records: [CalculationRecord] = []) {
        self.records = Array(records.prefix(Self.maximumCount))
    }

    private enum CodingKeys: String, CodingKey { case records }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode([CalculationRecord].self, forKey: .records)
        records = Array(decoded.prefix(Self.maximumCount))
    }

    public mutating func append(_ record: CalculationRecord) {
        records.insert(record, at: 0)
        if records.count > Self.maximumCount {
            records.removeLast(records.count - Self.maximumCount)
        }
    }

    public mutating func clear() { records.removeAll() }
}
