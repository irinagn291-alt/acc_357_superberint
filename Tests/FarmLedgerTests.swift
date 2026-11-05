import XCTest
@testable import Roostprint

@MainActor
final class FarmLedgerTests: XCTestCase {
    private func location() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: folder) }
        return folder
    }
    func testSalePersistsRejectsOversellingAndDeletionRestoresStock() throws {
        let file = try location().appending(path: "sales.json")
        let ledger = FarmLedger(fileURL: file)
        let batch = try PackingBatch(label: .blank(), collected: 23)
        try ledger.record(batch: batch, quantity: 6, kind: .sale, amountCents: 450, currency: "USD", customer: "Alex", note: "Paid")
        XCTAssertEqual(ledger.available(in: batch), 17)
        XCTAssertThrowsError(try ledger.record(batch: batch, quantity: 18, kind: .sale, amountCents: 1500, currency: "USD", customer: "", note: ""))
        let restored = FarmLedger(fileURL: file)
        XCTAssertEqual(restored.available(in: batch), 17)
        XCTAssertEqual(restored.movements.first?.amountCents, 450)
        try restored.remove(try XCTUnwrap(restored.movements.first).id)
        XCTAssertEqual(FarmLedger(fileURL: file).available(in: batch), 23)
    }
    func testAdjustmentsReduceStockWithoutCreatingRevenue() throws {
        let ledger = FarmLedger(fileURL: try location().appending(path: "sales.json"))
        let batch = try PackingBatch(label: .blank(), collected: 23)
        try ledger.record(batch: batch, quantity: 2, kind: .waste, amountCents: 0, currency: "USD", customer: "", note: "Cracked")
        try ledger.record(batch: batch, quantity: 3, kind: .household, amountCents: 0, currency: "USD", customer: "", note: "Breakfast")
        XCTAssertEqual(ledger.available(in: batch), 18)
        let report = FarmReport(batches: [batch], movements: ledger.movements, period: .all, currency: "USD")
        XCTAssertEqual(report.revenue, 0)
        XCTAssertEqual(report.household, 3)
        XCTAssertEqual(report.waste, 2)
    }
    func testCannotDeleteCollectionUntilLinkedActivityIsRemoved() throws {
        let folder = try location()
        let ledger = FarmLedger(fileURL: folder.appending(path: "sales.json"))
        let journal = BatchJournal(fileURL: folder.appending(path: "batches.json"), ledger: ledger)
        let batch = try PackingBatch(label: .blank(), collected: 10)
        try journal.save(batch)
        try ledger.record(batch: batch, quantity: 2, kind: .sale, amountCents: 200, currency: "GBP", customer: "", note: "")
        XCTAssertThrowsError(try journal.remove(batch.id))
        XCTAssertEqual(journal.batches.count, 1)
        try ledger.remove(try XCTUnwrap(ledger.movements.first).id)
        try journal.remove(batch.id)
        XCTAssertTrue(journal.batches.isEmpty)
    }
    func testReportFiltersDatesAndDoesNotMixCurrencies() throws {
        let now = Date()
        let batch = try PackingBatch(label: .blank(), collected: 23)
        func record(_ currency: String, _ date: Date) -> StockMovement {
            StockMovement(id: UUID(), batchID: batch.id, farm: "Farm", quantity: 2, kind: .sale,
                amountCents: 500, currency: currency, customer: "", note: "", date: date)
        }
        let records = [record("USD", now), record("GBP", now), record("USD", now.addingTimeInterval(-40 * 86400))]
        let report = FarmReport(batches: [batch], movements: records, period: .month, currency: "USD", now: now.addingTimeInterval(1))
        XCTAssertEqual(report.revenue, 500)
        XCTAssertEqual(report.sold, 4)
        XCTAssertEqual(report.salesCount, 1)
        XCTAssertEqual(report.collected, 23)
        XCTAssertEqual(FarmReport(batches: [], movements: records, period: .all, currency: "USD", now: now).revenue, 1000)
    }
    func testMoneyParsingAndCSVPreserveExactValuesAndEscapeText() throws {
        XCTAssertEqual(FarmLedger.cents(from: "12.34"), 1234)
        XCTAssertEqual(FarmLedger.cents(from: "4,5"), 450)
        for bad in ["-1", "1.001", "", "NaN", "1,000.00", "10000000"] { XCTAssertNil(FarmLedger.cents(from: bad)) }
        XCTAssertEqual(FarmReport.csvField("=SUM(A1)"), "\"'=SUM(A1)\"")
        XCTAssertEqual(FarmReport.csvField("Farm, \"East\""), "\"Farm, \"\"East\"\"\"")
    }
    func testFutureCollectionDoesNotCountAsStockYet() throws {
        let ledger = FarmLedger(fileURL: try location().appending(path: "sales.json"))
        var label = CartonLabel.blank()
        label.packedOn = Calendar.current.date(byAdding: .day, value: 2, to: .now)!
        let batch = try PackingBatch(label: label, collected: 23)
        XCTAssertEqual(ledger.available(in: batch), 0)
        XCTAssertThrowsError(try ledger.record(batch: batch, quantity: 1, kind: .sale, amountCents: 100, currency: "USD", customer: "", note: ""))
    }
    
    func testCorruptLedgerIsPreserved() throws {
        let file = try location().appending(path: "sales.json")
        let original = Data("broken".utf8)
        try original.write(to: file)
        let ledger = FarmLedger(fileURL: file)
        XCTAssertNotNil(ledger.loadError)
        let batch = try PackingBatch(label: .blank(), collected: 10)
        XCTAssertThrowsError(try ledger.record(batch: batch, quantity: 1, kind: .sale, amountCents: 100, currency: "USD", customer: "", note: ""))
        XCTAssertEqual(try Data(contentsOf: file), original)
    }
}
