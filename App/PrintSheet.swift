import PDFKit
import SwiftUI

struct PrintSheet: View {
    private let source: [CartonLabel]
    private let allowsCopies: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var paper: PaperSize = .a4
    @State private var copies = 6
    @State private var firstSlot = 1
    @State private var pageIndex = 0
    @State private var file: PrintFile?
    @State private var error: String?

    init(label: CartonLabel) {
        source = [label]
        allowsCopies = true
    }

    init(labels: [CartonLabel]) {
        source = labels
        allowsCopies = false
    }

    private var job: PrintJob {
        let labels = allowsCopies && !source.isEmpty ? Array(repeating: source[0], count: copies) : source
        return PrintJob(labels: labels, paper: paper, firstSlot: firstSlot)
    }

    private var readyFile: PrintFile? {
        file?.job == job ? file : nil
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > 620 && geometry.size.width > geometry.size.height {
                    HStack(spacing: 20) {
                        ScrollView { settings.padding(.vertical, 6) }
                            .frame(width: min(340, geometry.size.width * 0.40))
                        preview
                    }
                    .padding(.horizontal, 18).padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            settings
                            preview.frame(height: min(430, max(235, geometry.size.height * 0.48)))
                        }
                        .frame(maxWidth: 600).padding(18).frame(maxWidth: .infinity)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { exportBar }
            .foregroundStyle(PressInk.green)
            .background(PressInk.canvas)
            .navigationTitle("Print sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task(id: job) {
            let requested = job
            do {
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotLaunch.screen == nil {
                    try await Task.sleep(for: .milliseconds(100))
                }
                #else
                try await Task.sleep(for: .milliseconds(100))
                #endif
                prepare(requested)
            } catch { /* A newer configuration replaced this one. */ }
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Slug("Paper size")
            HStack(spacing: 8) {
                ForEach(PaperSize.allCases) { option in
                    Button {
                        paper = option
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option == paper ? "checkmark.circle.fill" : "circle")
                            Text(verbatim: option.title).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(option == paper ? PressInk.paper : PressInk.green)
                        .background(option == paper ? PressInk.green : PressInk.paper,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(PressInk.line) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(option == paper ? .isSelected : [])
                    .accessibilityIdentifier("paper-\(option.rawValue)")
                }
            }
            VStack(alignment: .leading, spacing: 7) {
                if allowsCopies {
                    Stepper(value: $copies, in: 1...SheetPress.maxLabels) {
                        Text("Label copies · \(copies)").fontWeight(.semibold)
                    }
                    .accessibilityLabel("Number of copies")
                    .accessibilityValue("\(copies)")
                    .accessibilityIdentifier("copiesStepper")
                    Divider()
                }
                HStack {
                    Text("Starting position").fontWeight(.semibold)
                    Spacer(minLength: 6)
                    Picker("Starting position", selection: $firstSlot) {
                        ForEach(1...6, id: \.self) { slot in
                            Text(Self.slotTitle(slot)).tag(slot)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityHint("Choose the next unused position on your partial sheet.")
                    .accessibilityIdentifier("firstSlotPicker")
                }
                Text("Start at the first position on a new sheet, or choose the next unused position on a partial sheet.")
                    .font(.footnote)
                    .foregroundStyle(PressInk.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.subheadline)
            .padding(12).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(PressInk.line) }
        }
    }

    static func slotTitle(_ slot: Int) -> String {
        let positions = ["top left", "top right", "middle left",
                         "middle right", "bottom left", "bottom right"]
        return "\(slot) · \(positions[slot - 1])"
    }

    private var preview: some View {
        VStack(spacing: 0) {
            if let result = readyFile {
                let page = min(pageIndex, result.document.pageCount - 1)
                SheetPreview(document: result.document, pageIndex: page)
                    .padding(7)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Preview. Sheet \(page + 1) of \(result.document.pageCount).")
                    .accessibilityIdentifier("pdfPreview")
                HStack {
                    Button { pageIndex = max(0, page - 1) } label: {
                        Image(systemName: "chevron.left").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Previous sheet").accessibilityIdentifier("previousPDFPage")
                    .disabled(page == 0)
                    Spacer()
                    Text("Sheet \(page + 1) of \(result.document.pageCount)")
                        .font(.subheadline.weight(.semibold)).monospacedDigit()
                        .accessibilityIdentifier("pdfPageNumber")
                    Spacer()
                    Button { pageIndex = min(result.document.pageCount - 1, page + 1) } label: {
                        Image(systemName: "chevron.right").frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Next sheet").accessibilityIdentifier("nextPDFPage")
                    .disabled(page + 1 >= result.document.pageCount)
                }
                .padding(.horizontal, 6)
            } else if let error {
                VStack(spacing: 10) {
                    Text(error).multilineTextAlignment(.center)
                    Button("Retry") { prepare(job) }
                }.padding()
            } else {
                ProgressView("Preparing PDF…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PressInk.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var exportBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Labels: \(job.labels.count) · 88 × 55 mm").font(.subheadline.bold())
            Text("Print at 100% scale and cut along the marks.")
                .font(.footnote).foregroundStyle(PressInk.muted)
            if let result = readyFile {
                ShareLink(item: result.url) { Label("Share PDF", systemImage: "square.and.arrow.up") }
                    .buttonStyle(PressButtonStyle()).accessibilityIdentifier("sharePDF")
            }
        }
        .frame(maxWidth: 600, alignment: .leading)
        .padding(.horizontal, 18).padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(PressInk.canvas).overlay(alignment: .top) { Divider() }
    }

    private func prepare(_ requested: PrintJob) {
        guard file?.job != requested else { return }
        error = nil
        do {
            file = try PrintFile(job: requested)
            pageIndex = 0
        } catch {
            file = nil
            self.error = error.localizedDescription
        }
    }
}

private struct PrintJob: Equatable {
    let labels: [CartonLabel]
    let paper: PaperSize
    let firstSlot: Int
}

private final class PrintFile {
    let job: PrintJob
    let url: URL
    let document: PDFDocument

    @MainActor init(job: PrintJob) throws {
        let url = try SheetPress.pdf(labels: job.labels, paper: job.paper, firstSlot: job.firstSlot)
        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            try? FileManager.default.removeItem(at: url)
            throw CocoaError(.fileReadCorruptFile)
        }
        self.job = job
        self.url = url
        self.document = document
    }

    deinit { try? FileManager.default.removeItem(at: url) }
}

private struct SheetPreview: UIViewRepresentable {
    let document: PDFDocument
    let pageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.displaysPageBreaks = false
        view.backgroundColor = .clear
        view.autoScales = true
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document !== document { view.document = document }
        if let page = document.page(at: pageIndex), view.currentPage !== page { view.go(to: page) }
    }
}
