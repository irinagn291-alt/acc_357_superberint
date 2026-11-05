import SwiftUI

struct MovementEditor: View {
    @EnvironmentObject private var journal: BatchJournal
    @EnvironmentObject private var ledger: FarmLedger
    @Environment(\.dismiss) private var dismiss
    @AppStorage("farm.currency") private var currency = "USD"
    @State private var kind: StockMovement.Kind
    private let preferredBatch: UUID?
    @State private var selectedID: UUID?
    @State private var quantity = ""
    @State private var amount = ""
    @State private var customer = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var error: String?
    private enum Field: Hashable { case quantity, amount, customer, note }
    @FocusState private var focusedField: Field?

    init(kind: StockMovement.Kind, preferredBatch: UUID? = nil) {
        _kind = State(initialValue: kind)
        self.preferredBatch = preferredBatch
    }
    private var available: [PackingBatch] {
        journal.batches.filter { ledger.available(in: $0) > 0 && Calendar.current.startOfDay(for: $0.label.packedOn) <= .now }
            .sorted { $0.label.packedOn < $1.label.packedOn }
    }
    private var selected: PackingBatch? { available.first { $0.id == selectedID } }
    private var earliest: Date { min(selected.map { Calendar.current.startOfDay(for: $0.label.packedOn) } ?? .now, .now) }
    private var valid: Bool {
        guard let selected, let quantity = Int(quantity), quantity > 0, quantity <= ledger.available(in: selected),
              customer.count <= 80, note.count <= 200, ledger.loadError == nil, journal.loadError == nil else { return false }
        return kind != .sale || FarmLedger.cents(from: amount) != nil
    }
    var body: some View {
        NavigationStack {
            Form {
                if available.isEmpty {
                    Section {
                        ContentUnavailableView("No eggs available", systemImage: "shippingbox",
                            description: Text("Save a collection first. Future-dated collections become available on their collection date."))
                    }
                } else {
                    Section("Collection") {
                        Picker("Use stock from", selection: $selectedID) {
                            ForEach(available) { batch in
                                Text("\(batch.label.flock) · \(batch.label.packedOn.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US")))) · \(ledger.available(in: batch)) left").tag(Optional(batch.id))
                            }
                        }.accessibilityIdentifier("movement.batch")
                        if let selected {
                            Text("\(ledger.available(in: selected)) eggs available. Oldest collection is selected first.").font(.caption)
                        }
                        TextField("Number of eggs", text: $quantity).keyboardType(.numberPad).focused($focusedField, equals: .quantity)
                            .accessibilityIdentifier("movement.quantity")
                        if let selected, let count = Int(quantity), count > ledger.available(in: selected) {
                            Text("Only \(ledger.available(in: selected)) eggs remain.").foregroundStyle(PressInk.red)
                        }
                    }
                    Section("Activity") {
                        Picker("Type", selection: $kind) { ForEach(StockMovement.Kind.allCases) { Text($0.title).tag($0) } }
                        DatePicker("Date", selection: $date, in: earliest...Date(), displayedComponents: .date)
                        if kind == .sale {
                            Picker("Currency", selection: $currency) { ForEach(FarmLedger.currencies, id: \.self) { Text($0).tag($0) } }
                            TextField("Total sale amount", text: $amount).keyboardType(.decimalPad).focused($focusedField, equals: .amount)
                                .accessibilityIdentifier("movement.amount")
                            Text("Enter the total received for this sale, not the price per egg.").font(.caption)
                            TextField("Customer (optional)", text: $customer).focused($focusedField, equals: .customer)
                                .accessibilityIdentifier("movement.customer")
                        }
                        TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(2...4).focused($focusedField, equals: .note)
                        Text("\(note.count)/200 characters").font(.caption).foregroundStyle(.secondary)
                    }
                    if let error { Section { Text(error).foregroundStyle(PressInk.red) } }
                }
            }
            .scrollContentBackground(.hidden).background(PressInk.canvas)
            .navigationTitle(kind == .sale ? "Record sale" : "Adjust stock").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!valid).accessibilityIdentifier("movement.save")
                }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focusedField = nil } }
            }
            .onAppear { selectedID = available.first { $0.id == preferredBatch }?.id ?? available.first?.id }
            .onChange(of: selectedID) { _, _ in if date < earliest { date = earliest } }
        }
    }
    private func save() {
        guard let selected, let count = Int(quantity) else { return }
        do {
            try ledger.record(batch: selected, quantity: count, kind: kind,
                amountCents: kind == .sale ? (FarmLedger.cents(from: amount) ?? -1) : 0,
                currency: currency, customer: kind == .sale ? customer : "", note: note, date: date)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
