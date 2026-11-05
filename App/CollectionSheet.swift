import SwiftUI

struct CollectionSheet: View {
    let onSelect: (CartonLabel?) -> Void
    @EnvironmentObject private var library: PressLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: CartonLabel?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Slug("Saved designs")
                        Spacer()
                        Slug(String(format: "№ / %02d", library.labels.count))
                    }
                    .foregroundStyle(PressInk.muted)
                    if let issue = library.loadError ?? error {
                        Text(issue).font(.callout).foregroundStyle(PressInk.red)
                    } else if library.labels.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            EggMark().frame(width: 44, height: 44)
                            Text("Your first design will appear here")
                                .font(.custom("Georgia-Bold", size: 25))
                            Text("Create a label in the workshop and tap Save. Duplicate it with a new date for your next collection.")
                                .font(.subheadline).foregroundStyle(PressInk.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(PressInk.paper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(PressInk.line) }
                    }
                    if !library.labels.isEmpty {
                        LazyVStack(spacing: 0) {
                            ForEach(library.labels) { label in
                                row(label)
                                Divider().overlay(PressInk.line)
                            }
                        }
                    }
                    Button { onSelect(nil) } label: {
                        Label("New label", systemImage: "plus")
                    }
                    .buttonStyle(PressButtonStyle())
                    .accessibilityIdentifier("newLabel")
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(PressInk.canvas)
            .foregroundStyle(PressInk.green)
            .navigationTitle("My designs")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .toolbarBackground(PressInk.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(PressInk.green)
            .alert("Delete this design?", isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ), presenting: pendingDeletion) { label in
                Button("Delete", role: .destructive) {
                    do {
                        try library.remove(label.id)
                        error = nil
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { label in
                Text("«\(label.flock)» on \(displayDate(label)) will be removed from your designs.")
            }
        }
    }

    private func row(_ label: CartonLabel) -> some View {
        HStack(spacing: 2) {
            Button { onSelect(label) } label: {
                HStack(spacing: 14) {
                    ScaledLabel(label: label)
                        .frame(width: 78)
                        .border(PressInk.line, width: 0.6)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(label.flock)
                            .font(.custom("Georgia-Bold", size: 18, relativeTo: .headline))
                            .lineLimit(2)
                        Text("\(displayDate(label)) · \(label.eggs) eggs · \(label.style.title)")
                            .font(.caption).foregroundStyle(PressInk.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label.flock), \(displayDate(label)), \(label.eggs) eggs, style \(label.style.title)")
            .accessibilityIdentifier("savedLabel")
            Menu {
                Button {
                    var copy = label
                    copy.id = UUID()
                    copy.packedOn = .now
                    onSelect(copy)
                } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                .accessibilityIdentifier("duplicateLabel")
                Button(role: .destructive) { pendingDeletion = label } label: {
                    Label("Delete design", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Design actions «\(label.flock)» on \(displayDate(label))")
            .accessibilityIdentifier("labelActions")
        }
    }

    private func displayDate(_ label: CartonLabel) -> String {
        label.packedOn.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US")))
    }
}
