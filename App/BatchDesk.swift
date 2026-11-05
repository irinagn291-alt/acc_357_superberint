import SwiftUI

struct BatchDesk: View {
    @EnvironmentObject private var journal: BatchJournal
    @Environment(\.dismiss) private var dismiss
    @State private var label: CartonLabel
    @State private var total = ""
    @State private var draftID = UUID()
    @State private var history = false
    @State private var path: [UUID] = []
    @State private var editLabel = false
    @State private var printing: PackingBatch?
    @State private var pendingRepeat: PackingBatch?
    @State private var pendingDelete: PackingBatch?
    @State private var issue: String?
    @FocusState private var enteringTotal: Bool
    #if DEBUG && targetEnvironment(simulator)
    @State private var screenshotRecord: PackingBatch?
    #endif

    init(label: CartonLabel, showHistory: Bool = false) {
        _label = State(initialValue: label)
        _history = State(initialValue: showHistory)
    }

    #if DEBUG && targetEnvironment(simulator)
    init(label: CartonLabel, screenshotTotal: String, screenshotHistory: Bool = false,
         screenshotRecord: PackingBatch? = nil) {
        _label = State(initialValue: label)
        _total = State(initialValue: screenshotTotal)
        _history = State(initialValue: screenshotHistory)
        _screenshotRecord = State(initialValue: screenshotRecord)
    }
    #endif

    private var plan: Result<PackingBatch, Error> {
        Result {
            guard let amount = Int(total.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw BatchIssue.invalidTotal
            }
            return try PackingBatch(id: draftID, label: label, collected: amount)
        }
    }

    private var saved: Bool { journal.batches.contains { $0.id == draftID } }

    var body: some View {
        NavigationStack(path: $path) {
            #if DEBUG && targetEnvironment(simulator)
            if let screenshotRecord, ScreenshotLaunch.screen == .batchRecord {
                receipt(screenshotRecord)
            } else {
                mainContent
            }
            #else
            mainContent
            #endif
        }
        .foregroundStyle(PressInk.green)
        .tint(PressInk.green)
        .onChange(of: total) { _, _ in forkAfterSave() }
        .onChange(of: label) { _, _ in forkAfterSave() }
        .sheet(isPresented: $editLabel) {
            EditLabelSheet(label: label) { label = $0 }
        }
        .sheet(item: $printing) { PrintSheet(labels: $0.printLabels) }
        .alert("Could not save changes", isPresented: Binding(
            get: { issue != nil }, set: { if !$0 { issue = nil } }
        )) { Button("Close") {} } message: { Text(issue ?? "") }
        .confirmationDialog("Delete this collection?", isPresented: Binding(
            get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }
        ), titleVisibility: .visible, presenting: pendingDelete) { batch in
            Button("Delete collection", role: .destructive) {
                do {
                    try journal.remove(batch.id)
                    path = []
                } catch { issue = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        } message: { batch in
            Text("This collection will be removed from the journal: «\(batch.label.flock)» on \(batch.label.packedOn.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US")))).")
        }
        .alert("Replace this calculation?", isPresented: Binding(
            get: { pendingRepeat != nil }, set: { if !$0 { pendingRepeat = nil } }
        ), presenting: pendingRepeat) { batch in
            Button("Start new collection") { repeatBatch(batch) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in Text("Your current calculation has unsaved changes.") }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                tab("Planner", icon: "shippingbox", archived: false)
                tab("Journal", icon: "book.closed", archived: true)
            }
            .padding(.horizontal, 20).padding(.vertical, 8).frame(maxWidth: 600)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if history { archive } else { calculator }
                }
                .padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .id(history)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PressInk.canvas)
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: UUID.self) { id in
            if let batch = journal.batches.first(where: { $0.id == id }) {
                receipt(batch)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            if enteringTotal {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { enteringTotal = false }
                }
            }
        }
    }

    private func tab(_ title: String, icon: String, archived: Bool) -> some View {
        let selected = history == archived
        return Button {
            enteringTotal = false
            history = archived
        } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(selected ? PressInk.paper : PressInk.green)
                .background(selected ? PressInk.green : PressInk.paper, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(archived ? "batchHistoryTab" : "batchPlannerTab")
    }

    @ViewBuilder private var calculator: some View {
        VStack(alignment: .leading, spacing: 5) {
            Slug("Packing desk").foregroundStyle(PressInk.red)
            Text("How many eggs?")
                .font(.custom("Georgia-Bold", size: 29, relativeTo: .title))
            Text("Calculate your cartons and prepare a label for each one.")
                .font(.subheadline).foregroundStyle(PressInk.muted)
        }

        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Eggs collected").font(.subheadline.bold())
                TextField("For example, 37", text: $total)
                    .keyboardType(.numberPad)
                    .focused($enteringTotal)
                    .font(.title3.monospacedDigit())
                    .padding(10)
                    .background(PressInk.canvas, in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel("Eggs collected").accessibilityIdentifier("batchTotal")
            }
            Stepper(value: $label.eggs, in: 1...30) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Carton capacity").font(.subheadline)
                    Text("\(label.eggs) eggs").font(.headline.monospacedDigit())
                }
            }
            .accessibilityIdentifier("batchCapacity")
            Divider()
            Button { enteringTotal = false; editLabel = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(label.flock).font(.subheadline.bold())
                        Text(label.packedOn, format: .dateTime.day().month(.wide).year())
                            .font(.caption).foregroundStyle(PressInk.muted)
                        Text("Edit label details").font(.caption).underline()
                    }
                    Spacer()
                    Image(systemName: "square.and.pencil")
                }.contentShape(Rectangle())
            }
            .buttonStyle(.plain).accessibilityIdentifier("batchEditLabel")
        }
        .padding(15).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 12))

        if total.isEmpty {
            Label("For example, 37 eggs in cartons of 10 need three full cartons and one carton of seven.",
                  systemImage: "lightbulb")
                .font(.subheadline).foregroundStyle(PressInk.muted)
        } else {
            switch plan {
            case .success(let batch):
                packingCard(batch)
                Button { enteringTotal = false; printing = batch } label: {
                    Label("Prepare labels", systemImage: "printer")
                }
                .buttonStyle(PressButtonStyle()).accessibilityIdentifier("batchPrint")

                Button {
                    enteringTotal = false
                    do { try journal.save(batch) } catch { issue = error.localizedDescription }
                } label: {
                    Label(saved ? "Saved to journal" : "Save collection", systemImage: saved ? "checkmark" : "book.closed")
                }
                .buttonStyle(PressButtonStyle(filled: false))
                .disabled(saved)
                .accessibilityIdentifier("batchSave")
            case .failure(let error):
                Label(error.localizedDescription, systemImage: "exclamationmark.circle")
                    .font(.subheadline).foregroundStyle(PressInk.red)
            }
        }
    }

    private func packingCard(_ batch: PackingBatch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Slug("Carton breakdown").foregroundStyle(PressInk.gold)
            Text(verbatim: batch.packingSummary)
                .font(.custom("Georgia-Bold", size: 27, relativeTo: .title2))
                .accessibilityIdentifier("batchPacking")
            Text("\(batch.boxCountText) · \(batch.labelCountText)")
                .font(.subheadline.bold())
            if let last = batch.cartonEggs.last, last < batch.label.eggs {
                Text("The partial carton label will show «\(last) eggs».")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).foregroundStyle(PressInk.paper).background(PressInk.green, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var archive: some View {
        Text("Collection journal").font(.custom("Georgia-Bold", size: 29, relativeTo: .title))
        if let message = journal.loadError {
            Text(message).foregroundStyle(PressInk.red)
        } else if journal.batches.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "book.closed").font(.title2)
                Text("Your collections will appear here").font(.headline)
                Text("Enter an egg count in the planner and save your first collection. Reprint its labels or start the next collection from the journal.")
                    .font(.subheadline).foregroundStyle(PressInk.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 12))
        } else {
            LazyVStack(spacing: 9) {
                ForEach(journal.batches) { batch in
                    Button { path.append(batch.id) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(batch.label.flock).font(.headline)
                                Text(batch.label.packedOn, format: .dateTime.day().month(.wide).year()).font(.caption)
                                Text("Collected \(batch.collected) eggs · \(batch.boxCountText)")
                                    .font(.subheadline)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption)
                        }
                        .padding(14).background(PressInk.paper, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(batch.label.flock), \(batch.label.packedOn.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US")))), collected \(batch.collected) eggs, \(batch.boxCountText)")
                    .accessibilityIdentifier("batchRecord")
                }
            }
        }
    }

    private func receipt(_ batch: PackingBatch) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Slug("Saved collection").foregroundStyle(PressInk.red)
                Text(batch.label.flock).font(.custom("Georgia-Bold", size: 29, relativeTo: .title))
                Text(batch.label.packedOn, format: .dateTime.day().month(.wide).year()).font(.headline)
                Text("Collected \(batch.collected) eggs · Carton capacity \(batch.label.eggs) eggs")
                Text("Label style — \(batch.label.style.title)").font(.subheadline).foregroundStyle(PressInk.muted)
                if !batch.label.note.isEmpty { Text(batch.label.note).italic().font(.subheadline) }
                packingCard(batch)
                Button { printing = batch } label: { Label("Reprint labels", systemImage: "printer") }
                    .buttonStyle(PressButtonStyle()).accessibilityIdentifier("batchReprint")
                Button {
                    if !total.isEmpty && !saved { pendingRepeat = batch } else { repeatBatch(batch) }
                } label: { Label("New collection today", systemImage: "plus") }
                    .buttonStyle(PressButtonStyle(filled: false)).accessibilityIdentifier("batchRepeat")
                Button(role: .destructive) { pendingDelete = batch } label: {
                    Label("Delete collection", systemImage: "trash").frame(minHeight: 44)
                }.accessibilityIdentifier("batchRemove")
            }
            .padding(20).frame(maxWidth: 600).frame(maxWidth: .infinity)
        }
        .background(PressInk.canvas).navigationTitle("Collection details").navigationBarTitleDisplayMode(.inline)
    }

    private func forkAfterSave() {
        if saved && (try? plan.get()) != journal.batches.first(where: { $0.id == draftID }) {
            draftID = UUID()
        }
    }

    private func repeatBatch(_ batch: PackingBatch) {
        draftID = UUID()
        label = batch.nextLabel()
        total = ""
        path = []
        history = false
    }
}
