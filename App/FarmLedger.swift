import Foundation
import SwiftUI

struct StockMovement: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case sale, household, waste
        var id: Self { self }
        var title: String {
            switch self { case .sale: "Sale"; case .household: "Household use"; case .waste: "Waste / breakage" }
        }
        var symbol: String {
            switch self { case .sale: "creditcard"; case .household: "house"; case .waste: "trash" }
        }
    }
    let id: UUID
    let batchID: UUID
    let farm: String
    let quantity: Int
    let kind: Kind
    let amountCents: Int
    let currency: String
    let customer: String
    let note: String
    let date: Date
}

enum LedgerIssue: LocalizedError {
    case insufficientStock, invalidAmount, invalidQuantity, invalidDate, unreadable, linkedCollection
    var errorDescription: String? {
        switch self {
        case .insufficientStock: "Not enough eggs remain in this collection. Check the quantity and try again."
        case .invalidAmount: "Enter a total sale amount with no more than two decimal places."
        case .invalidQuantity: "Enter a whole number of eggs and keep notes within 200 characters."
        case .invalidDate: "The activity date must be between the collection date and today."
        case .unreadable: "The activity ledger could not be read. Its original file has been preserved."
        case .linkedCollection: "This collection has sales or stock adjustments. Delete those activity records first to keep your stock accurate."
        }
    }
}

@MainActor
final class FarmLedger: ObservableObject {
    static let shared = FarmLedger()
    static let currencies = ["USD", "GBP", "EUR", "CAD", "AUD"]
    @Published private(set) var movements: [StockMovement] = []
    @Published private(set) var loadError: String?
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory.appending(path: "Roostprint/activity-v1.json")
        do {
            let records = try JSONDecoder().decode([StockMovement].self, from: Data(contentsOf: self.fileURL))
            var ids = Set<UUID>()
            guard records.allSatisfy({ ids.insert($0.id).inserted && $0.quantity > 0 && $0.quantity <= 360
                && $0.amountCents >= 0 && $0.amountCents <= 999_999_999
                && ($0.kind == .sale || $0.amountCents == 0)
                && Self.currencies.contains($0.currency) }) else { throw LedgerIssue.unreadable }
            movements = records
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
        } catch { loadError = LedgerIssue.unreadable.errorDescription }
    }

    func used(in batchID: UUID) -> Int { movements.filter { $0.batchID == batchID }.reduce(0) { $0 + $1.quantity } }
    func available(in batch: PackingBatch) -> Int {
        guard Calendar.current.startOfDay(for: batch.label.packedOn) <= Date() else { return 0 }
        return max(0, batch.collected - used(in: batch.id))
    }
    func hasMovements(for id: UUID) -> Bool { movements.contains { $0.batchID == id } }

    func record(batch: PackingBatch, quantity: Int, kind: StockMovement.Kind, amountCents: Int,
                currency: String, customer: String, note: String, date: Date = .now) throws {
        guard loadError == nil else { throw LedgerIssue.unreadable }
        guard (1...360).contains(quantity), customer.count <= 80, note.count <= 200 else { throw LedgerIssue.invalidQuantity }
        guard quantity <= available(in: batch) else { throw LedgerIssue.insufficientStock }
        guard (0...999_999_999).contains(amountCents), Self.currencies.contains(currency),
              kind == .sale || amountCents == 0 else { throw LedgerIssue.invalidAmount }
        guard date >= Calendar.current.startOfDay(for: batch.label.packedOn), date <= Date().addingTimeInterval(1) else {
            throw LedgerIssue.invalidDate
        }
        let record = StockMovement(id: UUID(), batchID: batch.id, farm: batch.label.flock, quantity: quantity,
            kind: kind, amountCents: amountCents, currency: currency,
            customer: customer.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines), date: date)
        try write([record] + movements)
    }

    func remove(_ id: UUID) throws { try write(movements.filter { $0.id != id }) }

    private func write(_ records: [StockMovement]) throws {
        guard loadError == nil else { throw LedgerIssue.unreadable }
        let data = try JSONEncoder().encode(records)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        movements = records
    }

    static func cents(from text: String) -> Int? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard clean.range(of: #"^\d{1,7}(\.\d{1,2})?$"#, options: .regularExpression) != nil else { return nil }
        let parts = clean.split(separator: ".")
        guard let whole = Int(parts[0]) else { return nil }
        let fraction = parts.count == 2 ? String(parts[1]).padding(toLength: 2, withPad: "0", startingAt: 0) : "00"
        return whole * 100 + (Int(fraction) ?? 0)
    }

    static func money(_ cents: Int, currency: String) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: currency).locale(Locale(identifier: "en_US")))
    }
}

enum ReportPeriod: String, CaseIterable, Identifiable {
    case week = "7 days", month = "30 days", quarter = "90 days", all = "All time"
    var id: Self { self }
    func start(now: Date = .now, calendar: Calendar = .current) -> Date {
        let days: Int
        switch self { case .week: days = 6; case .month: days = 29; case .quarter: days = 89; case .all: return .distantPast }
        return calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) ?? now
    }
}

struct FarmReport {
    let batches: [PackingBatch]
    let movements: [StockMovement]
    let currency: String
    init(batches: [PackingBatch], movements: [StockMovement], period: ReportPeriod, currency: String, now: Date = .now) {
        let start = period.start(now: now)
        self.batches = batches.filter { $0.label.packedOn >= start && $0.label.packedOn <= now }
        self.movements = movements.filter { $0.date >= start && $0.date <= now }
        self.currency = currency
    }
    var collected: Int { batches.reduce(0) { $0 + $1.collected } }
    var sold: Int { movements.filter { $0.kind == .sale }.reduce(0) { $0 + $1.quantity } }
    var waste: Int { movements.filter { $0.kind == .waste }.reduce(0) { $0 + $1.quantity } }
    var household: Int { movements.filter { $0.kind == .household }.reduce(0) { $0 + $1.quantity } }
    var revenue: Int { movements.filter { $0.kind == .sale && $0.currency == currency }.reduce(0) { $0 + $1.amountCents } }
    var salesCount: Int { movements.filter { $0.kind == .sale && $0.currency == currency }.count }
    var collectionDays: [(date: Date, eggs: Int)] {
        Dictionary(grouping: batches, by: { Calendar.current.startOfDay(for: $0.label.packedOn) })
            .map { (date: $0.key, eggs: $0.value.reduce(0) { $0 + $1.collected }) }.sorted { $0.date < $1.date }
    }
    var csv: String {
        var rows = [["Type", "Date", "Farm", "Eggs", "Sale total", "Currency", "Customer", "Note", "Collection ID"]]
        let formatter = ISO8601DateFormatter()
        for batch in batches.sorted(by: { $0.label.packedOn < $1.label.packedOn }) {
            rows.append(["Collection", formatter.string(from: batch.label.packedOn), batch.label.flock,
                String(batch.collected), "", "", "", batch.label.note, batch.id.uuidString])
        }
        for record in movements.sorted(by: { $0.date < $1.date }) {
            let amount = record.kind == .sale ? String(format: "%d.%02d", record.amountCents / 100, record.amountCents % 100) : ""
            rows.append([record.kind.title, formatter.string(from: record.date), record.farm, String(record.quantity),
                amount, record.kind == .sale ? record.currency : "", record.customer, record.note, record.batchID.uuidString])
        }
        return rows.map { $0.map(Self.csvField).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }
    static func csvField(_ value: String) -> String {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let protected = clean.first.map { "=+-@".contains($0) } == true ? "'" + value : value
        return "\"" + protected.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
