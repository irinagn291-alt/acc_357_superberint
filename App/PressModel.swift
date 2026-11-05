import Foundation
import SwiftUI

enum LabelStyle: String, Codable, CaseIterable, Identifiable {
    case farm, market, minimal

    var id: Self { self }
    var title: String {
        switch self {
        case .farm: "Farm"
        case .market: "Market"
        case .minimal: "Minimal"
        }
    }
}

struct CartonLabel: Identifiable, Codable, Equatable {
    var id: UUID
    var flock: String
    var eggs: Int
    var packedOn: Date
    var style: LabelStyle
    var note: String

    static func blank() -> Self {
        Self(id: UUID(), flock: "Willow Farm", eggs: 10, packedOn: .now, style: .farm, note: "From our hens")
    }

    var isValid: Bool {
        let name = flock.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.count <= 40 && (1...30).contains(eggs) && note.count <= 60
    }
}

private enum PressError: LocalizedError {
    case invalidLabel, unreadableLibrary, renderingFailed

    var errorDescription: String? {
        switch self {
        case .invalidLabel:
            "Check the farm name (up to 40 characters), carton size (1–30 eggs) and note (up to 60 characters)."
        case .unreadableLibrary:
            "Saved designs could not be read. The original file has been preserved."
        case .renderingFailed:
            "The print sheet could not be prepared."
        }
    }
}

@MainActor
final class PressLibrary: ObservableObject {
    @Published private(set) var labels: [CartonLabel] = []
    private let fileURL: URL
    private var loadFailed = false
    var loadError: String? { loadFailed ? PressError.unreadableLibrary.errorDescription : nil }

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? URL.applicationSupportDirectory
            .appending(path: "Roostprint/labels.json")
        do {
            labels = try JSONDecoder().decode([CartonLabel].self, from: Data(contentsOf: self.fileURL))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            // The first saved label creates the library.
        } catch {
            loadFailed = true
        }
    }

    func save(_ label: CartonLabel) throws {
        guard label.isValid else { throw PressError.invalidLabel }
        var clean = label
        clean.flock = label.flock.trimmingCharacters(in: .whitespacesAndNewlines)
        clean.note = label.note.trimmingCharacters(in: .whitespacesAndNewlines)
        try write([clean] + labels.filter { $0.id != label.id })
    }

    func remove(_ id: UUID) throws {
        try write(labels.filter { $0.id != id })
    }

    private func write(_ updated: [CartonLabel]) throws {
        guard !loadFailed else { throw PressError.unreadableLibrary }
        let data = try JSONEncoder().encode(updated)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        labels = updated
    }
}

enum PaperSize: String, CaseIterable, Identifiable {
    case a4, letter

    var id: Self { self }
    var title: String { self == .a4 ? "A4" : "US Letter" }

    fileprivate var points: CGSize {
        switch self {
        case .a4: CGSize(width: 210 * 72 / 25.4, height: 297 * 72 / 25.4)
        case .letter: CGSize(width: 612, height: 792)
        }
    }
}

@MainActor
enum SheetPress {
    static let maxLabels = 60

    static func pdf(label: CartonLabel, paper: PaperSize) throws -> URL {
        try pdf(labels: Array(repeating: label, count: 6), paper: paper, firstSlot: 1)
    }

    static func pdf(labels: [CartonLabel], paper: PaperSize, firstSlot: Int = 1) throws -> URL {
        guard (1...maxLabels).contains(labels.count), (1...6).contains(firstSlot)
        else { throw PressError.renderingFailed }
        guard labels.allSatisfy(\.isValid) else { throw PressError.invalidLabel }
        let data = NSMutableData()
        var page = CGRect(origin: .zero, size: paper.points)
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: &page, nil)
        else { throw PressError.renderingFailed }

        let mm: CGFloat = 72 / 25.4
        let cell = CGSize(width: 88 * mm, height: 55 * mm)
        let gap = 8 * mm
        let left = (page.width - 2 * cell.width - gap) / 2
        let bottom = (page.height - 3 * cell.height - 2 * gap) / 2
        var renderedCount = 0
        context.beginPDFPage(nil)
        var start = 0
        while start < labels.count {
            let label = labels[start]
            let end = labels[start...].firstIndex { $0 != label } ?? labels.endIndex
            let artwork = CartonFace(label: label)
                .frame(width: 300, height: 187.5)
                .environment(\.colorScheme, .light)
                .environment(\.dynamicTypeSize, .medium)
            // Full cartons share one typeset face. A remainder with a different count
            // starts a new run, even when its saved template has the same identifier.
            ImageRenderer(content: artwork).render(rasterizationScale: 3) { size, draw in
                guard size.width > 0, size.height > 0 else { return }
                for index in start..<end {
                    let slot = (firstSlot - 1 + index) % 6
                    if slot == 0 && index > 0 {
                        context.endPDFPage()
                        context.beginPDFPage(nil)
                    }

                    // Slot 1 is the top left on paper. PDF coordinates start at the bottom.
                    let box = CGRect(x: left + CGFloat(slot % 2) * (cell.width + gap),
                                     y: bottom + CGFloat(2 - slot / 2) * (cell.height + gap),
                                     width: cell.width, height: cell.height)
                    context.saveGState()
                    context.clip(to: box)
                    context.translateBy(x: box.minX, y: box.minY)
                    context.scaleBy(x: box.width / size.width, y: box.height / size.height)
                    draw(context)
                    context.restoreGState()
                    cropMarks(around: box, in: context, mm: mm)
                    renderedCount += 1
                }
            }
            start = end
        }
        context.endPDFPage()
        context.closePDF()
        guard renderedCount == labels.count, data.length > 0 else { throw PressError.renderingFailed }

        let url = FileManager.default.temporaryDirectory
            .appending(path: "Roostprint-\(paper.title)-\(UUID().uuidString).pdf")
        try (data as Data).write(to: url, options: .atomic)
        return url
    }

    private static func cropMarks(around box: CGRect, in context: CGContext, mm: CGFloat) {
        context.setStrokeColor(gray: 0.35, alpha: 1)
        context.setLineWidth(0.4)
        for (x, dx) in [(box.minX, CGFloat(-1)), (box.maxX, CGFloat(1))] {
            for (y, dy) in [(box.minY, CGFloat(-1)), (box.maxY, CGFloat(1))] {
                context.move(to: CGPoint(x: x + dx * mm, y: y))
                context.addLine(to: CGPoint(x: x + dx * 3.5 * mm, y: y))
                context.move(to: CGPoint(x: x, y: y + dy * mm))
                context.addLine(to: CGPoint(x: x, y: y + dy * 3.5 * mm))
            }
        }
        context.strokePath()
    }
}
