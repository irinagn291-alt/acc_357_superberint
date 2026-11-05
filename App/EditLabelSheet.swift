import SwiftUI

struct EditLabelSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var working: CartonLabel
    @FocusState private var focused: Field?
    private let original: CartonLabel
    @State private var confirmDiscard = false
    private let onApply: (CartonLabel) -> Void
    private enum Field { case flock, note }

    init(label: CartonLabel, onApply: @escaping (CartonLabel) -> Void) {
        original = label
        _working = State(initialValue: label)
        self.onApply = onApply
    }

    private var hasChanges: Bool { working != original }

    private var nameIssue: String? {
        let name = working.flock.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return "Enter a farm name to apply your changes." }
        return name.count > 40 ? "Shorten the farm name to 40 characters." : nil
    }

    var body: some View {
        editingForm.interactiveDismissDisabled(hasChanges)
    }

    @ViewBuilder private var discardActions: some View {
        Button("Discard changes", role: .destructive) { dismiss() }
        Button("Keep editing", role: .cancel) {}
    }

    private var editingForm: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Slug("Design desk").foregroundStyle(PressInk.red)
                        Text("Label details")
                            .font(.custom("Georgia-Bold", size: 30, relativeTo: .title))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        fieldHeader("Farm name", count: working.flock.count, max: 40)
                        HStack(spacing: 4) {
                            TextField("For example, Willow Farm", text: $working.flock)
                                .focused($focused, equals: .flock)
                                .textInputAutocapitalization(.sentences)
                                .submitLabel(.done)
                                .accessibilityLabel("Farm name")
                                .accessibilityIdentifier("flockName")
                            if !working.flock.isEmpty {
                                clearButton(.flock, title: "Clear farm name", id: "clearFlock")
                            }
                        }.pressTextField()
                        if let nameIssue {
                            validationMessage(nameIssue)
                        }
                    }
                    VStack(spacing: 13) {
                        Stepper(value: $working.eggs, in: 1...30) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Eggs per carton").font(.subheadline)
                                Text("\(working.eggs) eggs").font(.headline.monospacedDigit())
                            }
                        }
                        .accessibilityIdentifier("eggStepper")
                        Divider()
                        DatePicker("Collection date", selection: $working.packedOn, displayedComponents: .date)
                            .font(.subheadline).datePickerStyle(.compact)
                    }.padding(13)
                    .background(PressInk.paper, in: RoundedRectangle(cornerRadius: 10))
                    .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(PressInk.line) }

                    VStack(alignment: .leading, spacing: 8) {
                        fieldHeader("Note", count: working.note.count, max: 60)
                        HStack(spacing: 4) {
                            TextField("An optional short note", text: $working.note, axis: .vertical)
                                .focused($focused, equals: .note).lineLimit(2...3)
                                .accessibilityLabel("Note").accessibilityIdentifier("labelNote")
                            if !working.note.isEmpty {
                                clearButton(.note, title: "Clear note", id: "clearNote")
                            }
                        }.pressTextField()
                        if working.note.count > 60 {
                            validationMessage("Shorten the note to 60 characters or leave it blank.")
                        }
                    }
                }
                .frame(maxWidth: 540).padding(20).frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button {
                    working.flock = working.flock.trimmingCharacters(in: .whitespacesAndNewlines)
                    working.note = working.note.trimmingCharacters(in: .whitespacesAndNewlines)
                    onApply(working)
                    dismiss()
                } label: {
                    Label("Apply", systemImage: "checkmark")
                }
                .buttonStyle(PressButtonStyle())
                .disabled(!working.isValid).opacity(working.isValid ? 1 : 0.5)
                .accessibilityIdentifier("applyEdit")
                .frame(maxWidth: 540).padding(.horizontal, 20).padding(.vertical, 8)
                .frame(maxWidth: .infinity).background(PressInk.canvas)
            }
            .background(PressInk.canvas.ignoresSafeArea())
            .foregroundStyle(PressInk.green)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                }
                if focused != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { focused = nil }
                    }
                }
            }
        }
        .confirmationDialog("Discard your changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            discardActions
        }
    }

    private func clearButton(_ field: Field, title: String, id: String) -> some View {
        Button {
            if field == .flock { working.flock = "" } else { working.note = "" }
            focused = field
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(PressInk.muted)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }

    private func validationMessage(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.circle")
            .font(.footnote)
            .foregroundStyle(PressInk.red)
            .accessibilityElement(children: .combine)
    }

    private func fieldHeader(_ title: String, count: Int, max: Int) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(count)/\(max)").font(.caption.monospacedDigit())
                .foregroundStyle(count > max ? PressInk.red : PressInk.muted)
        }
    }
}

private extension View {
    func pressTextField() -> some View {
        self.padding(.leading, 12).padding(.trailing, 4).frame(minHeight: 48)
            .background(PressInk.paper, in: RoundedRectangle(cornerRadius: 9))
            .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(PressInk.line) }
    }
}
