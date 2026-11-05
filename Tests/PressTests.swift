import CoreGraphics
import XCTest
@testable import Roostprint

final class PressTests: XCTestCase {
    @MainActor
    func testSaveEditDeleteAndReload() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "library/labels.json")
        let library = PressLibrary(fileURL: file)
        var first = CartonLabel.blank()
        var second = CartonLabel.blank()
        second.flock = "Sunny Meadow"
        try library.save(first)
        try library.save(second)
        XCTAssertEqual(PressLibrary(fileURL: file).labels, [second, first])

        first.style = .market
        first.eggs = 12
        try library.save(first)
        XCTAssertEqual(PressLibrary(fileURL: file).labels, [first, second])
        first.flock = "  "
        XCTAssertThrowsError(try library.save(first))
        XCTAssertEqual(library.labels.first?.flock, "Willow Farm")
        try library.remove(first.id)
        XCTAssertEqual(PressLibrary(fileURL: file).labels, [second])
    }

    @MainActor
    func testCorruptLibraryIsPreserved() async throws {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        let bad = Data("broken".utf8)
        try bad.write(to: file)
        let library = PressLibrary(fileURL: file)
        XCTAssertNotNil(library.loadError)
        XCTAssertThrowsError(try library.save(.blank()))
        XCTAssertEqual(try Data(contentsOf: file), bad)
    }

    @MainActor
    func testPrintsSixLabelsOnBothPaperSizes() async throws {
        var previous: URL?
        for paper in [PaperSize.a4, .letter, .letter] {
            let url = try SheetPress.pdf(label: .blank(), paper: paper)
            defer { try? FileManager.default.removeItem(at: url) }
            XCTAssertNotEqual(previous, url)
            previous = url
            let document = try XCTUnwrap(CGPDFDocument(url as CFURL))
            XCTAssertEqual(document.numberOfPages, 1)
            let page = try XCTUnwrap(document.page(at: 1))
            let bounds = page.getBoxRect(.mediaBox)
            XCTAssertEqual(bounds.width, paper == .a4 ? 595.28 : 612, accuracy: 0.1)
            XCTAssertEqual(bounds.height, paper == .a4 ? 841.89 : 792, accuracy: 0.1)

            let mm: CGFloat = 72 / 25.4
            for row in 0..<3 {
                for column in 0..<2 {
                    let label = CGRect(x: (bounds.width - 184 * mm) / 2 + CGFloat(column) * 96 * mm,
                                       y: (bounds.height - 181 * mm) / 2 + CGFloat(row) * 63 * mm,
                                       width: 88 * mm, height: 55 * mm)
                    let context = try XCTUnwrap(CGContext(data: nil, width: 88, height: 55,
                        bitsPerComponent: 8, bytesPerRow: 88, space: CGColorSpaceCreateDeviceGray(),
                        bitmapInfo: CGImageAlphaInfo.none.rawValue))
                    context.setFillColor(gray: 1, alpha: 1)
                    context.fill(CGRect(x: 0, y: 0, width: 88, height: 55))
                    context.scaleBy(x: 1 / mm, y: 1 / mm)
                    context.translateBy(x: -label.minX, y: -label.minY)
                    context.drawPDFPage(page)
                    let data = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
                    let pixels = UnsafeBufferPointer(start: data, count: 88 * 55)
                    XCTAssertGreaterThan(pixels.filter { $0 < 155 }.count, 80,
                                         "Empty label: row \(row), column \(column)")
                }
            }
        }
    }
}
