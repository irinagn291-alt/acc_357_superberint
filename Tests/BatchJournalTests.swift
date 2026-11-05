import XCTest
@testable import Roostprint

final class BatchJournalTests: XCTestCase {
    func testSharedCartonCalculatorLimitsAndRemainder() throws {
        let plan = try XCTUnwrap(BoxPlan(collected: 23, capacity: 10))
        XCTAssertEqual(plan.cartons, [10, 10, 3])
        XCTAssertEqual(plan.summary, "2 × 10 + 1 × 3")
        XCTAssertEqual(plan.count, 3)
        XCTAssertEqual(BoxPlan(collected: 360, capacity: 6)?.count, 60)
        XCTAssertNil(BoxPlan(collected: 61, capacity: 1))
        XCTAssertNil(BoxPlan(collected: 1, capacity: 0))
        XCTAssertNil(BoxPlan(collected: 0, capacity: 10))
    }

    @MainActor
    func testCompanionSummaryTracksSavesAndDeletion() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let book = BatchJournal(fileURL: file)
        XCTAssertEqual(book.companionSummary, .empty)
        let batch = try PackingBatch(label: .blank(), collected: 23)
        try book.save(batch)
        let summary = book.companionSummary
        XCTAssertEqual(summary.value, "23 eggs")
        XCTAssertTrue(summary.detail.contains("2 × 10 + 1 × 3"))
        XCTAssertEqual(summary.items.first?.id, batch.id.uuidString)
        let decoded = try JSONDecoder().decode(CompanionSnapshot.self, from: JSONEncoder().encode(summary))
        XCTAssertEqual(summary, decoded)
        try book.remove(batch.id)
        XCTAssertEqual(book.companionSummary, .empty)
    }

    func testPackingHandlesPartialOnlyExactFullAndMaximum() throws {
        let label = CartonLabel.blank()
        for (total, expected) in [(3, [3]), (10, [10]), (20, [10, 10]), (27, [10, 10, 7])] {
            let batch = try PackingBatch(label: label, collected: total)
            XCTAssertEqual(batch.cartonEggs, expected)
            XCTAssertEqual(batch.printLabels.map(\.eggs), expected)
            XCTAssertEqual(batch.printLabels.map(\.flock), expected.map { _ in label.flock })
            XCTAssertEqual(batch.printLabels.map(\.packedOn), expected.map { _ in label.packedOn })
        }
        var small = label
        small.eggs = 6
        XCTAssertEqual(try PackingBatch(label: small, collected: 360).cartonEggs.count, 60)
        small.eggs = 1
        for invalid in [-1, 0, 61, 361, Int.max] {
            XCTAssertThrowsError(try PackingBatch(label: small, collected: invalid))
        }
        XCTAssertNoThrow(try PackingBatch(label: small, collected: 60))
        small.eggs = 0
        XCTAssertThrowsError(try PackingBatch(label: small, collected: 10))
    }

    @MainActor
    func testSnapshotsSurviveReopenAndRepeatingDoesNotReplaceHistory() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "batches.json")
        let book = BatchJournal(fileURL: url)
        let original = try PackingBatch(label: .blank(), collected: 24)
        try book.save(original)
        try book.save(original)
        let nextDay = Date(timeIntervalSince1970: 1_800_000_000)
        let nextLabel = original.nextLabel(on: nextDay)
        XCTAssertEqual(nextLabel.packedOn, nextDay)
        XCTAssertNotEqual(nextLabel.id, original.label.id)
        let second = try PackingBatch(label: nextLabel, collected: 11)
        XCTAssertThrowsError(try book.save(PackingBatch(id: original.id, label: nextLabel, collected: 11)))
        try book.save(second)
        XCTAssertEqual(BatchJournal(fileURL: url).batches, [second, original])
        try book.remove(second.id)
        XCTAssertEqual(BatchJournal(fileURL: url).batches.first?.printLabels, original.printLabels)
    }

    @MainActor
    func testUnreadableJournalIsNeverOverwritten() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        let bad = Data("[{}]".utf8)
        try bad.write(to: url)
        let book = BatchJournal(fileURL: url)
        XCTAssertNotNil(book.loadError)
        XCTAssertThrowsError(try book.save(PackingBatch(label: .blank(), collected: 7)))
        XCTAssertEqual(try Data(contentsOf: url), bad)
    }
}
