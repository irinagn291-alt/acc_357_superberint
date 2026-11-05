import SwiftUI

struct PressGuide: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contact = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Slug("Getting started").foregroundStyle(PressInk.red)
                    Text("From collection to carton")
                        .font(.custom("Georgia-Bold", size: 30, relativeTo: .title))
                        .accessibilityAddTraits(.isHeader)

                    instruction(1, "Log collections", "Use Log a collection on Overview. Enter the egg count and farm details, then save. Each saved collection adds to your stock.")
                    instruction(2, "Track sales and stock", "Record sales from available collections. Enter the total received and currency. From Stock, open a collection to record household use or waste. Deleting an activity record restores its eggs.")
                    instruction(3, "Review your results", "Insights shows collections, eggs sold, household use, waste and revenue for 7, 30 or 90 days, or all time. Revenue is separated by currency. Export the selected period as a CSV report.")
                    Divider().overlay(PressInk.line)
                    Text("Labels & printing").font(.title2.bold())
                    instruction(1, "Personalize your label", "Enter your farm name, collection date and a short note. Choose a label style for your cartons.")
                    instruction(2, "Plan the cartons", "Tap Plan a batch. Enter the number of eggs collected and the capacity of each carton.")
                    VStack(alignment: .leading, spacing: 7) {
                        Slug("Example")
                        Text("23 eggs · 10 per carton").font(.headline)
                        Text("This makes two full cartons and one carton of three. The labels will show 10, 10 and 3 eggs.")
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(PressInk.gold.opacity(0.24), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .combine)

                    instruction(3, "Print your labels", "Tap Prepare labels and choose A4 or US Letter. Print the 88 × 55 mm labels at 100% scale and cut along the marks.")
                    Divider().overlay(PressInk.line)
                    Text("Your next collection")
                        .font(.headline).accessibilityAddTraits(.isHeader)
                    Text("Save your design. In My designs, open its menu and choose Duplicate to make a copy with today's date. Save a collection from the batch planner to keep its quantity and carton breakdown.")
                        .font(.body)
                    NavigationLink {
                        PrivacyPolicyPage()
                    } label: {
                        Label("Privacy policy", systemImage: "hand.raised")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    }
                    .accessibilityIdentifier("openPrivacy")
                    Button { contact = true } label: {
                        Label("Contact Us", systemImage: "envelope")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    }
                    .accessibilityIdentifier("roost.contact")
                }
                .frame(maxWidth: 565, alignment: .leading)
                .padding(20).frame(maxWidth: .infinity)
            }
            .background(PressInk.canvas)
            .foregroundStyle(PressInk.green)
            .sheet(isPresented: $contact) { ContactPage() }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func instruction(_ number: Int, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(format: "%02d", number))
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundStyle(PressInk.red).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline).accessibilityAddTraits(.isHeader)
                Text(body).font(.body)
            }
        }
    }
}

private struct PrivacyPolicyPage: View {
    // The app and the public page use the same document.
    private let paragraphs = PolicyReader.read()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(paragraphs.indices, id: \.self) { index in
                    let paragraph = paragraphs[index]
                    if paragraph.tag == "h1" {
                        Text(paragraph.text).font(.title.bold()).accessibilityAddTraits(.isHeader)
                    } else if paragraph.tag == "h2" {
                        Text(paragraph.text).font(.headline).padding(.top, 5).accessibilityAddTraits(.isHeader)
                    } else {
                        Text(paragraph.text).font(.body)
                    }
                }
                if paragraphs.isEmpty {
                    ContentUnavailableView("Could not open the policy", systemImage: "doc.text")
                }
            }
            .frame(maxWidth: 565, alignment: .leading).padding(20).frame(maxWidth: .infinity)
        }
        .background(PressInk.canvas).foregroundStyle(PressInk.green)
        .navigationTitle("Privacy").navigationBarTitleDisplayMode(.inline)
    }
}

private final class PolicyReader: NSObject, XMLParserDelegate {
    struct Paragraph {
        let tag: String
        let text: String
    }

    private var paragraphs: [Paragraph] = []
    private var tag: String?
    private var text = ""

    static func read() -> [Paragraph] {
        guard let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "html"),
              let parser = XMLParser(contentsOf: url) else { return [] }
        let reader = PolicyReader()
        parser.delegate = reader
        return parser.parse() ? reader.paragraphs : []
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if ["h1", "h2", "p"].contains(elementName), attributeDict["class"] != "brand" {
            tag = elementName
            text = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if tag != nil { text += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if tag == elementName {
            paragraphs.append(Paragraph(tag: elementName, text: text))
            tag = nil
        }
    }
}
