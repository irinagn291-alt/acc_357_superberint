import Foundation
import SwiftUI

struct PackingBatch: Identifiable, Codable, Equatable {
    let id: UUID
    let label: CartonLabel
    let collected: Int
    let cartonEggs: [Int]

    init(id: UUID = UUID(), label: CartonLabel, collected: Int) throws {
        guard label.isValid else { throw BatchIssue.invalidLabel }
        guard (1...360).contains(collected) else { throw BatchIssue.invalidTotal }
        guard let plan = BoxPlan(collected: collected, capacity: label.eggs) else { throw BatchIssue.tooManyCartons }

        self.id = id
        self.label = label
        self.collected = collected
        self.cartonEggs = plan.cartons
    }

    var printLabels: [CartonLabel] {
        cartonEggs.map { eggs in
            var carton = label
            carton.eggs = eggs
            return carton
        }
    }

    var boxCountText: String { counted("carton", "cartons", "cartons") }
    var labelCountText: String { counted("label", "labels", "labels") }

    private func counted(_ single: String, _ few: String, _ many: String) -> String {
        let count = cartonEggs.count
        let word = count == 1 ? single : many
        return "\(count) \(word)"
    }

    var packingSummary: String {
        let full = collected / label.eggs
        let remainder = collected % label.eggs
        if full == 0 { return "1 × \(remainder)" }
        if remainder == 0 { return "\(full) × \(label.eggs)" }
        return "\(full) × \(label.eggs) + 1 × \(remainder)"
    }

    func nextLabel(on date: Date = .now) -> CartonLabel {
        var next = label
        next.id = UUID()
        next.packedOn = date
        return next
    }
}

enum BatchIssue: LocalizedError {
    case invalidLabel, invalidTotal, tooManyCartons, unreadable, changedSavedBatch

    var errorDescription: String? {
        switch self {
        case .invalidLabel: "Check the farm details and carton capacity."
        case .invalidTotal: "Enter a whole number from 1 to 360."
        case .tooManyCartons: "A batch can contain up to 60 cartons. Increase carton capacity or split the collection."
        case .unreadable: "The collection journal could not be read. The original file has been preserved."
        case .changedSavedBatch: "This batch is already saved. Create a new batch for the next collection."
        }
    }
}

@MainActor
final class BatchJournal: ObservableObject {
    @Published private(set) var batches: [PackingBatch] = []
    private(set) var loadError: String?
    private let fileURL: URL
    private let ledger: FarmLedger

    init(fileURL: URL? = nil, ledger: FarmLedger = .shared) {
        self.ledger = ledger
        self.fileURL = fileURL ?? URL.applicationSupportDirectory.appending(path: "Roostprint/batches.json")
        do {
            let archived = try JSONDecoder().decode([PackingBatch].self, from: Data(contentsOf: self.fileURL))
            var ids = Set<UUID>()
            for record in archived {
                let expected = try PackingBatch(id: record.id, label: record.label, collected: record.collected)
                guard record == expected && ids.insert(record.id).inserted else { throw BatchIssue.unreadable }
            }
            batches = archived
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            // A new journal is written only after the first explicit save.
        } catch {
            loadError = BatchIssue.unreadable.errorDescription
        }
    }

    func save(_ batch: PackingBatch) throws {
        if let previous = batches.first(where: { $0.id == batch.id }) {
            guard previous == batch else { throw BatchIssue.changedSavedBatch }
            return
        }
        try write([batch] + batches)
    }

    func remove(_ id: UUID) throws {
        guard !ledger.hasMovements(for: id) else { throw LedgerIssue.linkedCollection }
        try write(batches.filter { $0.id != id })
    }

    private func write(_ records: [PackingBatch]) throws {
        guard loadError == nil else { throw BatchIssue.unreadable }
        let data = try JSONEncoder().encode(records)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        batches = records
    }
}

extension BatchJournal {
    var companionSummary: CompanionSnapshot {
        guard let latest = batches.first else { return .empty }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let items = batches.prefix(12).map { batch in
            CompanionItem(id: batch.id.uuidString, title: batch.label.flock,
                detail: "\(batch.collected) eggs · \(batch.packingSummary) · \(formatter.string(from: batch.label.packedOn))")
        }
        return CompanionSnapshot(title: latest.label.flock, value: "\(latest.collected) eggs",
            detail: latest.packingSummary + " · " + formatter.string(from: latest.label.packedOn),
            items: items, updated: .now)
    }
}
