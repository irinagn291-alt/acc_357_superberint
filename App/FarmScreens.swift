import SwiftUI
import Charts
import UniformTypeIdentifiers

private enum FarmTab: String { case overview, stock, sales, insights, labels }

struct FarmHome: View {
    @State private var tab: FarmTab = .overview
    init() {}
    #if DEBUG && targetEnvironment(simulator)
    init(screenshotTab: String) {
        _tab = State(initialValue: screenshotTab == "stock" ? .stock : screenshotTab == "sales" ? .sales : screenshotTab == "insights" ? .insights : .overview)
    }
    #endif
    var body: some View {
        TabView(selection: $tab) {
            FarmOverview().tabItem { Label("Overview", systemImage: "square.grid.2x2") }.tag(FarmTab.overview)
            StockScreen().tabItem { Label("Stock", systemImage: "shippingbox") }.tag(FarmTab.stock)
            SalesScreen().tabItem { Label("Sales", systemImage: "creditcard") }.tag(FarmTab.sales)
            InsightsScreen().tabItem { Label("Insights", systemImage: "chart.bar") }.tag(FarmTab.insights)
            Studio().tabItem { Label("Labels", systemImage: "tag") }.tag(FarmTab.labels)
        }
        .tint(PressInk.green)
        .onOpenURL { url in if url.scheme == Brand.route { tab = .stock } }
    }
}

struct FarmMetric: View {
    let title: String
    let value: String
    var symbol = "circle"
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.caption.bold()).foregroundStyle(PressInk.muted)
            Text(value).font(.system(.title2, design: .rounded, weight: .bold)).minimumScaleFactor(0.65).lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .padding(14).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PressInk.line))
        .accessibilityElement(children: .combine)
    }
}

struct FarmOverview: View {
    @EnvironmentObject private var journal: BatchJournal
    @EnvironmentObject private var ledger: FarmLedger
    @AppStorage("farm.currency") private var currency = "USD"
    @State private var collection = false
    @State private var sale = false
    @State private var help = false
    private var report: FarmReport { FarmReport(batches: journal.batches, movements: ledger.movements, period: .week, currency: currency) }
    private var remaining: Int { journal.batches.reduce(0) { $0 + ledger.available(in: $1) } }
    private var oldest: [PackingBatch] { journal.batches.filter { ledger.available(in: $0) > 0 }.sorted { $0.label.packedOn < $1.label.packedOn } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Slug("Your farm, in focus").foregroundStyle(PressInk.gold)
                        Text("Every egg accounted for.").font(.custom("Georgia-Bold", size: 32, relativeTo: .largeTitle))
                        Text("From today's collection to the next customer.").font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(22)
                    .foregroundStyle(PressInk.paper).background(PressInk.green, in: RoundedRectangle(cornerRadius: 18))
                    if let error = journal.loadError ?? ledger.loadError { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(PressInk.red) }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        FarmMetric(title: "Eggs on hand", value: "\(remaining)", symbol: "shippingbox")
                        FarmMetric(title: "Collected · 7 days", value: "\(report.collected)", symbol: "tray.and.arrow.down")
                        FarmMetric(title: "Sold · 7 days", value: "\(report.sold)", symbol: "bag")
                        FarmMetric(title: "Revenue · \(currency)", value: FarmLedger.money(report.revenue, currency: currency), symbol: "banknote")
                    }
                    Button { collection = true } label: { Label("Log a collection", systemImage: "plus.circle") }
                        .buttonStyle(PressButtonStyle()).accessibilityIdentifier("farm.addCollection")
                    Button { sale = true } label: { Label("Record a sale", systemImage: "creditcard") }
                        .buttonStyle(PressButtonStyle(filled: false)).accessibilityIdentifier("farm.addSale")
                    HStack {
                        Text("Use oldest stock first").font(.title3.bold())
                        Spacer()
                        Text("\(oldest.count) \(oldest.count == 1 ? "collection" : "collections")").font(.caption).foregroundStyle(PressInk.muted)
                    }
                    if oldest.isEmpty {
                        Text("Save your first collection to start tracking stock. Sales and household use will update the remaining quantity.")
                            .foregroundStyle(PressInk.muted)
                    } else {
                        ForEach(oldest.prefix(3)) { batch in
                            NavigationLink { StockDetail(batch: batch) } label: { StockRow(batch: batch, remaining: ledger.available(in: batch)) }
                                .buttonStyle(.plain)
                        }
                    }
                }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(PressInk.canvas).foregroundStyle(PressInk.green)
            .navigationTitle("SuperBerint").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button { help = true } label: { Image(systemName: "questionmark.circle") }.accessibilityLabel("Help") }
            .sheet(isPresented: $collection) { BatchDesk(label: .blank()) }
            .sheet(isPresented: $sale) { MovementEditor(kind: .sale) }
            .sheet(isPresented: $help) { PressGuide() }
        }
    }
}

struct StockRow: View {
    let batch: PackingBatch
    let remaining: Int
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "shippingbox").font(.title2).foregroundStyle(PressInk.red)
            VStack(alignment: .leading, spacing: 5) {
                Text(batch.label.flock).font(.headline)
                Text(batch.label.packedOn, format: .dateTime.month(.abbreviated).day().year()).font(.caption).foregroundStyle(PressInk.muted)
                Text("\(batch.collected) collected · \(batch.label.eggs) per carton").font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(remaining)").font(.title2.bold()).monospacedDigit()
                Text("on hand").font(.caption2)
            }
        }.padding(15).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
    }
}

struct StockScreen: View {
    @EnvironmentObject private var journal: BatchJournal
    @EnvironmentObject private var ledger: FarmLedger
    @State private var query = ""
    @State private var availableOnly = true
    @State private var journalSheet = false
    private var batches: [PackingBatch] {
        journal.batches.filter { (!availableOnly || ledger.available(in: $0) > 0) && (query.isEmpty || $0.label.flock.localizedCaseInsensitiveContains(query)) }
            .sorted { $0.label.packedOn < $1.label.packedOn }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Only available stock", isOn: $availableOnly)
                    if let error = journal.loadError ?? ledger.loadError { Text(error).foregroundStyle(PressInk.red) }
                }
                Section("Collections · oldest first") {
                    if batches.isEmpty {
                        ContentUnavailableView("No matching stock", systemImage: "shippingbox", description: Text("Log a collection or turn off the available-stock filter."))
                    }
                    ForEach(batches) { batch in
                        NavigationLink { StockDetail(batch: batch) } label: { StockRow(batch: batch, remaining: ledger.available(in: batch)) }
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 6))
                    }
                }
            }
            .scrollContentBackground(.hidden).background(PressInk.canvas)
            .navigationTitle("Stock").searchable(text: $query, prompt: "Find a farm")
            .toolbar { Button("Collections", systemImage: "book.closed") { journalSheet = true }.accessibilityIdentifier("farm.collections") }
            .sheet(isPresented: $journalSheet) { BatchDesk(label: .blank(), showHistory: true) }
        }
    }
}

struct StockDetail: View {
    let batch: PackingBatch
    @EnvironmentObject private var ledger: FarmLedger
    @State private var sale = false
    @State private var adjust = false
    private var records: [StockMovement] { ledger.movements.filter { $0.batchID == batch.id }.sorted { $0.date > $1.date } }
    var body: some View {
        List {
            Section {
                FarmMetric(title: "Eggs remaining", value: "\(ledger.available(in: batch)) / \(batch.collected)", symbol: "shippingbox")
                    .accessibilityIdentifier("stock.remaining")
                LabeledContent("Farm", value: batch.label.flock)
                LabeledContent("Collected", value: batch.label.packedOn.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US"))))
                LabeledContent("Collection age", value: "\(max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: batch.label.packedOn), to: .now).day ?? 0)) days")
                LabeledContent("Carton plan", value: batch.packingSummary)
                if !batch.label.note.isEmpty { Text(batch.label.note) }
            }
            Section {
                Button("Record a sale", systemImage: "creditcard") { sale = true }.disabled(ledger.available(in: batch) == 0)
                Button("Household use or waste", systemImage: "minus.circle") { adjust = true }.disabled(ledger.available(in: batch) == 0)
            }
            Section("Stock activity") {
                if records.isEmpty { Text("No sales or adjustments for this collection yet.").foregroundStyle(.secondary) }
                ForEach(records) { record in
                    NavigationLink { MovementDetail(record: record) } label: { MovementRow(record: record) }
                }
            }
        }
        .scrollContentBackground(.hidden).background(PressInk.canvas)
        .navigationTitle("Collection stock").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $sale) { MovementEditor(kind: .sale, preferredBatch: batch.id) }
        .sheet(isPresented: $adjust) { MovementEditor(kind: .household, preferredBatch: batch.id) }
    }
}

struct MovementRow: View {
    let record: StockMovement
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.kind.symbol).foregroundStyle(PressInk.red)
            VStack(alignment: .leading, spacing: 5) {
                Text(record.customer.isEmpty ? record.kind.title : record.customer).font(.headline)
                Text("\(record.farm) · \(record.quantity) eggs").font(.subheadline)
                Text(record.date, format: .dateTime.month(.abbreviated).day()).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if record.kind == .sale {
                VStack(alignment: .trailing) {
                    Text(FarmLedger.money(record.amountCents, currency: record.currency)).bold()
                    Text(record.currency).font(.caption2).foregroundStyle(.secondary)
                }
            } else { Text("−\(record.quantity)").bold() }
        }.accessibilityElement(children: .combine)
    }
}

struct SalesScreen: View {
    @EnvironmentObject private var ledger: FarmLedger
    @State private var sale = false
    @State private var query = ""
    @State private var salesOnly = true
    private var records: [StockMovement] {
        ledger.movements.filter { (!salesOnly || $0.kind == .sale) && (query.isEmpty || ($0.customer + " " + $0.farm).localizedCaseInsensitiveContains(query)) }
            .sorted { $0.date > $1.date }
    }
    var body: some View {
        NavigationStack {
            List {
                Section { Toggle("Sales only", isOn: $salesOnly) }
                if let error = ledger.loadError { Text(error).foregroundStyle(PressInk.red) }
                if records.isEmpty {
                    ContentUnavailableView("Your activity starts here", systemImage: "creditcard", description: Text("Record a sale from available stock. Turn off Sales only to see household use and waste."))
                }
                ForEach(records) { record in
                    NavigationLink { MovementDetail(record: record) } label: { MovementRow(record: record) }
                }
            }
            .scrollContentBackground(.hidden).background(PressInk.canvas)
            .navigationTitle("Sales & activity")
            .searchable(text: $query, prompt: "Customer or farm")
            .toolbar { Button("Add sale", systemImage: "plus") { sale = true }.accessibilityIdentifier("sales.add") }
            .sheet(isPresented: $sale) { MovementEditor(kind: .sale) }
        }
    }
}

struct MovementDetail: View {
    let record: StockMovement
    @EnvironmentObject private var ledger: FarmLedger
    @Environment(\.dismiss) private var dismiss
    @State private var deleting = false
    @State private var error: String?
    var body: some View {
        List {
            Section("Record") {
                LabeledContent("Type", value: record.kind.title)
                LabeledContent("Farm", value: record.farm)
                LabeledContent("Eggs", value: "\(record.quantity)")
                LabeledContent("Date", value: record.date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US"))))
                if record.kind == .sale {
                    LabeledContent("Sale total", value: FarmLedger.money(record.amountCents, currency: record.currency) + " " + record.currency)
                    LabeledContent("Customer", value: record.customer.isEmpty ? "Not specified" : record.customer)
                }
                if !record.note.isEmpty { Text(record.note) }
            }
            Section {
                Button("Delete record", role: .destructive) { deleting = true }.accessibilityIdentifier("activity.delete")
            } footer: { Text("Deleting this record returns \(record.quantity) eggs to the original collection. To correct a record, delete it and add the replacement.") }
        }
        .scrollContentBackground(.hidden).background(PressInk.canvas).navigationTitle(record.kind.title)
        .confirmationDialog("Delete this record and restore stock?", isPresented: $deleting, titleVisibility: .visible) {
            Button("Delete and restore stock", role: .destructive) {
                do { try ledger.remove(record.id); dismiss() } catch { self.error = error.localizedDescription }
            }
        }
        .alert("Could not delete", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") {}
        } message: { Text(error ?? "") }
    }
}

struct InsightsScreen: View {
    @EnvironmentObject private var journal: BatchJournal
    @EnvironmentObject private var ledger: FarmLedger
    @AppStorage("farm.currency") private var currency = "USD"
    @State private var period: ReportPeriod = .month
    @State private var exporting = false
    @State private var exportError: String?
    private var report: FarmReport { FarmReport(batches: journal.batches, movements: ledger.movements, period: period, currency: currency) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Period", selection: $period) { ForEach(ReportPeriod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    HStack {
                        Text("Revenue currency").font(.subheadline)
                        Spacer()
                        Picker("Currency", selection: $currency) { ForEach(FarmLedger.currencies, id: \.self) { Text($0).tag($0) } }
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        FarmMetric(title: "Eggs collected", value: "\(report.collected)", symbol: "tray.and.arrow.down")
                        FarmMetric(title: "Eggs sold", value: "\(report.sold)", symbol: "bag")
                        FarmMetric(title: "Revenue · \(currency)", value: FarmLedger.money(report.revenue, currency: currency), symbol: "banknote")
                        FarmMetric(title: "Household / waste", value: "\(report.household) / \(report.waste)", symbol: "house")
                    }
                    Text("Collection trend").font(.title2.bold())
                    if report.collectionDays.isEmpty {
                        ContentUnavailableView("No collections in this period", systemImage: "chart.bar", description: Text("Choose a longer period or save a collection."))
                    } else {
                        Chart(report.collectionDays, id: \.date) { day in
                            BarMark(x: .value("Date", day.date, unit: .day), y: .value("Eggs", day.eggs)).foregroundStyle(PressInk.green)
                        }.frame(height: 200).chartYAxisLabel("Eggs")
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, (Calendar.current.dateComponents([.day], from: report.collectionDays.first!.date, to: report.collectionDays.last!.date).day ?? 0) / 4))) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        ForEach(report.collectionDays.suffix(7), id: \.date) { day in
                            HStack { Text(day.date, format: .dateTime.month(.abbreviated).day()); Spacer(); Text("\(day.eggs) eggs").bold() }
                                .font(.subheadline)
                        }
                    }
                    Text("\(report.batches.count) \(report.batches.count == 1 ? "collection" : "collections") · \(report.salesCount) \(report.salesCount == 1 ? "sale" : "sales") in \(currency)")
                        .font(.subheadline).foregroundStyle(PressInk.muted)
                    Text("Revenue includes only sales recorded in \(currency). Egg counts include all currencies. Revenue is sales income, before expenses.")
                        .font(.caption).foregroundStyle(PressInk.muted)
                    Button { exporting = true } label: { Label("Export period as CSV", systemImage: "square.and.arrow.up") }
                        .buttonStyle(PressButtonStyle()).accessibilityIdentifier("insights.export")
                        .disabled(report.batches.isEmpty && report.movements.isEmpty)
                    Text("The export includes collections, sales, household use and waste for the selected dates, with each sale's original currency.")
                        .font(.caption).foregroundStyle(PressInk.muted)
                }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.background(PressInk.canvas).foregroundStyle(PressInk.green).navigationTitle("Insights")
            .fileExporter(isPresented: $exporting, document: FarmCSV(text: report.csv), contentType: .commaSeparatedText,
                          defaultFilename: "SuperBerint-\(period.rawValue.replacingOccurrences(of: " ", with: "-"))") { result in
                if case .failure(let error) = result { exportError = error.localizedDescription }
            }
            .alert("Could not export", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK") {}
            } message: { Text(exportError ?? "") }
        }
    }
}

struct FarmCSV: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}
