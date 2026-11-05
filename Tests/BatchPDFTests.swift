import PDFKit
import XCTest
@testable import Roostprint

final class BatchPDFTests: XCTestCase {
    @MainActor
    func testPartialSheetContinuesOnNextPageWithActualCartonContents() async throws {
        let full = CartonLabel.blank()
        var remainder = full
        remainder.eggs = 3
        // Both cartons belong to the same template, including its ID.
        for paper in [PaperSize.a4, .letter] {
            let batch = try SheetPress.pdf(labels: [full, remainder], paper: paper, firstSlot: 6)
            defer { try? FileManager.default.removeItem(at: batch) }
            let document = try XCTUnwrap(CGPDFDocument(batch as CFURL))
            XCTAssertEqual(document.numberOfPages, 2)
            let first = try XCTUnwrap(document.page(at: 1))
            let second = try XCTUnwrap(document.page(at: 2))
            let readable = try XCTUnwrap(PDFDocument(url: batch))
            XCTAssertTrue(try XCTUnwrap(readable.page(at: 0)?.string).contains("10 eggs"))
            XCTAssertTrue(try XCTUnwrap(readable.page(at: 1)?.string).contains("3 eggs"))
            XCTAssertTrue(try pixels(of: first, slot: 6).contains { $0 < 150 })
            XCTAssertTrue(try pixels(of: second, slot: 1).contains { $0 < 150 })
            for slot in 1...5 {
                XCTAssertFalse(try pixels(of: first, slot: slot).contains { $0 < 240 })
            }
            for slot in 2...6 {
                XCTAssertFalse(try pixels(of: second, slot: slot).contains { $0 < 240 })
            }
        }
    }

    @MainActor
    func testRejectsInvalidJobsBeforeCreatingFiles() async throws {
        let label = CartonLabel.blank()
        var invalid = label
        invalid.eggs = 0
        XCTAssertThrowsError(try SheetPress.pdf(labels: [], paper: .a4))
        XCTAssertThrowsError(try SheetPress.pdf(labels: Array(repeating: label, count: 61), paper: .a4))
        XCTAssertThrowsError(try SheetPress.pdf(labels: [label], paper: .a4, firstSlot: 0))
        XCTAssertThrowsError(try SheetPress.pdf(labels: [label], paper: .a4, firstSlot: 7))
        XCTAssertThrowsError(try SheetPress.pdf(labels: [label, invalid], paper: .a4))
    }

    private func pixels(of page: CGPDFPage, slot: Int) throws -> [UInt8] {
        let bounds = page.getBoxRect(.mediaBox)
        let mm: CGFloat = 72 / 25.4
        let left = (bounds.width - 184 * mm) / 2
        let bottom = (bounds.height - 181 * mm) / 2
        let x = left + CGFloat((slot - 1) % 2) * 96 * mm
        let y = bottom + CGFloat(2 - (slot - 1) / 2) * 63 * mm
        // Include 3.5 mm crop marks outside each 88 × 55 mm label.
        let region = CGRect(x: x - 4 * mm, y: y - 4 * mm, width: 96 * mm, height: 63 * mm)
        let width = Int(region.width.rounded(.down))
        let height = Int(region.height.rounded(.down))
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue))
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: -region.minX, y: -region.minY)
        context.drawPDFPage(page)
        let data = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        return Array(UnsafeBufferPointer(start: data, count: width * height))
    }
}
