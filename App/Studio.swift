import SwiftUI

@main
struct RoostprintApp: App {
    @StateObject private var launch = AppLaunch()
    @StateObject private var library = PressLibrary()
    @StateObject private var batches = BatchJournal()
    @StateObject private var ledger = FarmLedger.shared

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG && targetEnvironment(simulator)
                if let screen = ScreenshotLaunch.screen {
                    ScreenshotRoot(screen: screen)
                } else {
                    normalRoot
                }
                #else
                normalRoot
                #endif
            }
            .environment(\.locale, Locale(identifier: "en_US"))
            .preferredColorScheme(launch.mode == .webContent ? nil : .light)
            .tint(launch.mode == .webContent ? nil : PressInk.green)
        }
    }

    private var normalRoot: some View {
        Group {
            switch launch.mode {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .webContent:
                if let url = launch.contentURL { InAppBrowser(url: url) }
                else { FarmHome() }
            case .nativeInterface:
                FarmHome()
            }
        }
            .task { launch.start() }
            .environmentObject(library)
            .environmentObject(batches)
            .environmentObject(ledger)
            .onChange(of: batches.batches, initial: true) { _, _ in
                let snapshot = batches.companionSummary
                WidgetPublisher.shared.publish(title: snapshot.title, value: snapshot.value,
                    detail: snapshot.detail, items: snapshot.items)
            }
    }
}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotScreen: String, CaseIterable {
    case overview, stock, sales, insights
    static let storeScreens: [Self] = [.overview, .stock, .sales, .insights, .workshop, .printSheet]
    case workshop, labelEditor = "label-editor", batchCalculator = "batch-calculator"
    case printSheet = "print-sheet", savedLabels = "saved-labels"
    case batchJournal = "batch-journal", batchRecord = "batch-record"
}

enum ScreenshotLaunch {
    static var screen: ScreenshotScreen? {
        let process = ProcessInfo.processInfo
        let args = process.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
            return args[index + 1]
        }
        if args.contains("-ReviewScreen") {
            return value(after: "-ReviewScreen").flatMap(ScreenshotScreen.init(rawValue:))
        }
        let environmentFlag = process.environment["APPSTORE_SCREENSHOTS"]
        let environmentEnabled = environmentFlag.map { !["", "0", "false", "no"].contains($0.lowercased()) } ?? false
        guard args.contains("-AppStoreScreenshots") || environmentEnabled else { return nil }
        let indexValue = value(after: "-AppStoreScreenshotScreen")
            ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(indexValue), ScreenshotScreen.storeScreens.indices.contains(index) else { return nil }
        return ScreenshotScreen.storeScreens[index]
    }
}

@MainActor
private final class ScreenshotData: ObservableObject {
    let label: CartonLabel
    let record: PackingBatch
    let library: PressLibrary
    let journal: BatchJournal
    let ledger: FarmLedger

    init() {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "Roostprint-Screenshot-\(UUID().uuidString)", directoryHint: .isDirectory)
        let demoLibrary = PressLibrary(fileURL: directory.appending(path: "labels.json"))
        let demoJournal = BatchJournal(fileURL: directory.appending(path: "batches.json"))
        let demoLedger = FarmLedger(fileURL: directory.appending(path: "ledger.json"))
        let date = Date.now
        let first = CartonLabel(id: UUID(), flock: "Willow Farm", eggs: 12, packedOn: date,
                                style: .farm, note: "Fresh from our hens")
        try! demoLibrary.save(first)
        var firstBatch: PackingBatch!
        for offset in (0..<14).reversed() {
            let collectedOn = Calendar.current.date(byAdding: .day, value: -offset, to: date)!
            let label = CartonLabel(id: UUID(), flock: offset % 3 == 0 ? "Sunny Meadow" : "Willow Farm", eggs: 12, packedOn: collectedOn, style: offset % 3 == 0 ? .market : .farm, note: "Fresh from our hens")
            let batch = try! PackingBatch(label: label, collected: 42 + (offset % 5) * 6)
            try! demoJournal.save(batch)
            try! demoLedger.record(batch: batch, quantity: 24, kind: .sale, amountCents: 1200, currency: "USD", customer: ["Saturday Market", "The Corner Cafe", "Farm Shop"][offset % 3], note: "Two cartons", date: collectedOn)
            if offset % 4 == 0 { try! demoLedger.record(batch: batch, quantity: 6, kind: .household, amountCents: 0, currency: "USD", customer: "", note: "For the kitchen", date: collectedOn) }
            if offset == 0 { firstBatch = batch }
        }
        label = first
        record = firstBatch
        library = demoLibrary
        journal = demoJournal
        ledger = demoLedger
    }
}

@MainActor
private struct ScreenshotRoot: View {
    let screen: ScreenshotScreen
    @StateObject private var data = ScreenshotData()

    @ViewBuilder var body: some View {
        Group {
            switch screen {
            case .overview, .stock, .sales, .insights:
                FarmHome(screenshotTab: screen.rawValue)
            case .workshop:
                Studio(screenshotLabel: data.label)
            case .labelEditor:
                EditLabelSheet(label: data.label) { _ in }
            case .batchCalculator:
                BatchDesk(label: data.label, screenshotTotal: "37")
            case .printSheet:
                PrintSheet(label: data.label)
            case .savedLabels:
                CollectionSheet { _ in }
            case .batchJournal:
                BatchDesk(label: data.label, screenshotTotal: "", screenshotHistory: true)
            case .batchRecord:
                BatchDesk(label: data.label, screenshotTotal: "", screenshotRecord: data.record)
            }
        }
        .environmentObject(data.library)
        .environmentObject(data.journal)
        .environmentObject(data.ledger)
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
    }
}
#endif

private enum StudioSheet: String, Identifiable {
    case edit, collection, print, batches, guide
    var id: Self { self }
}

struct Studio: View {
    @EnvironmentObject private var library: PressLibrary
    @SceneStorage("studio.draft") private var draftData: Data?
    @SceneStorage("studio.edited") private var storedEdited = false
    #if DEBUG && targetEnvironment(simulator)
    @State private var screenshotEdited = false
    #endif
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var label = CartonLabel.blank()
    @State private var sheet: StudioSheet?
    @State private var pending: CartonLabel?
    @State private var error: String?

    init() {}

    #if DEBUG && targetEnvironment(simulator)
    init(screenshotLabel: CartonLabel) {
        _label = State(initialValue: screenshotLabel)
    }
    #endif

    private var edited: Bool {
        get {
            #if DEBUG && targetEnvironment(simulator)
            if ScreenshotLaunch.screen != nil { return screenshotEdited }
            #endif
            return storedEdited
        }
        nonmutating set {
            #if DEBUG && targetEnvironment(simulator)
            if ScreenshotLaunch.screen != nil {
                screenshotEdited = newValue
                return
            }
            #endif
            storedEdited = newValue
        }
    }

    private var saved: Bool { library.labels.contains(label) }
    private var isSample: Bool {
        !library.labels.contains(where: { $0.id == label.id }) &&
            label.flock == "Willow Farm" && label.note == "From our hens"
    }
    private var problem: Binding<Bool> {
        Binding(get: { error != nil }, set: { if !$0 { error = nil } })
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 740 && !typeSize.isAccessibilitySize
            VStack(spacing: 0) {
                masthead
                Divider().overlay(PressInk.line)
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Slug("Label workshop").foregroundStyle(PressInk.red)
                            Text("Label studio")
                                .font(.custom("Georgia-Bold", size: 38, relativeTo: .largeTitle))
                            Text("Plan your cartons or create a reusable label design.")
                                .font(.subheadline).foregroundStyle(PressInk.muted)
                        }
                        .padding(.vertical, 2)

                        batchEntry

                        if wide {
                            HStack(alignment: .top, spacing: 26) {
                                ProofBoard(label: label)
                                controls.frame(maxWidth: 335)
                            }
                        } else {
                            ProofBoard(label: label)
                            controls
                        }
                    }
                    .padding(.horizontal, wide ? 30 : 20).padding(.vertical, 17)
                    .frame(maxWidth: wide ? 1040 : 540)
                    .frame(maxWidth: .infinity)
                }
                Divider().overlay(PressInk.line)
                let footer = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 5)) : AnyLayout(HStackLayout(spacing: 10))
                footer {
                    Button {
                        save()
                    } label: {
                        Label(saved ? "Saved" : "Save", systemImage: saved ? "checkmark" : "bookmark")
                    }
                    .buttonStyle(PressButtonStyle(filled: false))
                    .disabled(saved).accessibilityIdentifier("saveLabel")
                    Button { sheet = .print } label: {
                        Label("Print design", systemImage: "printer")
                    }
                    .buttonStyle(PressButtonStyle()).accessibilityIdentifier("printLabel")
                }
                .frame(maxWidth: 540).padding(.horizontal, 20).padding(.vertical, 10)
            }.frame(maxWidth: .infinity)
        }
        .background(PressInk.canvas.ignoresSafeArea())
        .foregroundStyle(PressInk.green)
        .onAppear {
            #if DEBUG && targetEnvironment(simulator)
            if ScreenshotLaunch.screen != nil { return }
            #endif
            if let draftData, let stored = try? JSONDecoder().decode(CartonLabel.self, from: draftData),
               stored.isValid { label = stored }
        }
        .onChange(of: label) { _, updated in
            #if DEBUG && targetEnvironment(simulator)
            if ScreenshotLaunch.screen != nil { return }
            #endif
            draftData = try? JSONEncoder().encode(updated)
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .edit:
                EditLabelSheet(label: label) { updated in
                    if updated != label { label = updated; edited = true }
                }
            case .collection:
                collectionSheet
            case .print:
                PrintSheet(label: label)
            case .batches:
                BatchDesk(label: label)
            case .guide:
                PressGuide()
            }
        }
        .alert("Could not save", isPresented: problem) {
            Button("Close") {}
        } message: { Text(error ?? "") }
    }

    private var collectionSheet: some View {
        CollectionSheet { selected in
            let next = selected ?? .blank()
            if edited && !saved && next != label {
                pending = next
            } else {
                switchTo(next)
                sheet = nil
            }
        }
        .confirmationDialog("Save your changes?", isPresented: Binding(
            get: { pending != nil }, set: { if !$0 { pending = nil } }
        ), titleVisibility: .visible, presenting: pending) { next in
            Button("Save and continue") {
                if save() {
                    switchTo(next)
                    sheet = nil
                }
            }
            Button("Continue without saving", role: .destructive) {
                switchTo(next)
                sheet = nil
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var masthead: some View {
        HStack {
            EggMark().frame(width: 29, height: 32)
            Text("SuperBerint")
                .font(.custom("Georgia-Bold", size: 23)).tracking(-1)
            Spacer()
            Button { sheet = .guide } label: {
                Image(systemName: "questionmark.circle").font(.title3)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityLabel("Help").accessibilityIdentifier("guide")
            Button { sheet = .collection } label: {
                Label("My designs", systemImage: "tray.full")
                    .labelStyle(.titleOnly)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .overlay(Capsule().strokeBorder(PressInk.line))
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain).accessibilityIdentifier("collection")
        }
        .frame(maxWidth: 980).padding(.horizontal, 20).padding(.vertical, 2)
    }

    private var batchEntry: some View {
        Button { sheet = .batches } label: {
            HStack(spacing: 12) {
                Image(systemName: "shippingbox")
                    .font(.title2.weight(.medium))
                    .frame(width: 44, height: 44)
                    .background(PressInk.gold, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Plan a batch")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Cartons, labels and collection history")
                        .font(.footnote).foregroundStyle(PressInk.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.subheadline.bold())
            }
            .padding(12)
            .background(PressInk.gold.opacity(0.20), in: RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(PressInk.green.opacity(0.19)) }
        }
        .buttonStyle(.plain).accessibilityIdentifier("openBatches")
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button { sheet = .edit } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.pencil").font(.title3)
                        .frame(width: 38, height: 38).background(PressInk.green.opacity(0.08), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Slug(isSample ? "Sample · customize" : "Label details").foregroundStyle(PressInk.muted)
                        Text(isSample ? "Add your farm details" : "\(label.flock) · \(label.eggs) eggs")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold)).lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                .padding(11).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 9))
                .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(PressInk.line) }
            }.buttonStyle(.plain).accessibilityIdentifier("editLabel")

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text("Label style").font(.custom("Georgia-Bold", size: 21, relativeTo: .title3))
                    Spacer()
                    if !typeSize.isAccessibilitySize { Slug("3 styles").foregroundStyle(PressInk.muted) }
                }
                let tiles = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
                tiles {
                    ForEach(LabelStyle.allCases) { style in
                        Button {
                            if label.style != style { label.style = style; edited = true }
                        } label: {
                            StyleTile(style: style, selected: style == label.style)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(style.title)
                        .accessibilityAddTraits(style == label.style ? .isSelected : [])
                        .accessibilityIdentifier("style-" + style.rawValue)
                    }
                }
            }

        }
    }

    private func switchTo(_ next: CartonLabel) {
        label = next
        edited = false
    }

    @discardableResult private func save() -> Bool {
        do {
            try library.save(label)
            if let normalized = library.labels.first(where: { $0.id == label.id }) { label = normalized }
            edited = false
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}

private struct StyleTile: View {
    let style: LabelStyle
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topTrailing) {
                swatch
                    .frame(maxWidth: .infinity).frame(height: 37)
                    .clipped()
                    .accessibilityHidden(true)
                if selected {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .black))
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.white).background(PressInk.green, in: Circle()).padding(3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(style.title).font(.system(.caption, design: .rounded, weight: .bold))
        }
        .padding(7)
        .background(PressInk.paper, in: RoundedRectangle(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? PressInk.green : PressInk.line, lineWidth: selected ? 1.7 : 1) }
    }

    @ViewBuilder private var swatch: some View {
        switch style {
        case .farm:
            ZStack {
                Color(red: 0.91, green: 0.85, blue: 0.67)
                HStack(spacing: 3) {
                    Image(systemName: "leaf.fill").font(.system(size: 12))
                    Text("Aa").font(.custom("Georgia-BoldItalic", size: 25))
                    Image(systemName: "leaf.fill").font(.system(size: 12)).scaleEffect(x: -1)
                }
            }
        case .market:
            ZStack {
                PressInk.gold
                HStack(spacing: 2) {
                    ForEach(0..<10) { _ in Rectangle().fill(PressInk.red.opacity(0.20)).frame(width: 4) }
                }.rotationEffect(.degrees(20))
                Text("AA").font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(PressInk.red)
            }
        case .minimal:
            ZStack {
                PressInk.green
                HStack(spacing: 4) {
                    Rectangle().frame(width: 12, height: 1)
                    Text("Aa").font(.system(size: 24, weight: .light))
                    Rectangle().frame(width: 12, height: 1)
                }.foregroundStyle(PressInk.paper)
            }
        }
    }
}
