import SwiftUI

enum Brand {
    static let name = "SuperBerint"
    static let group = "group.studio.roostprint.press"
    static let route = "roostprint"
    static let widget = "studio.roostprint.press.summary"
    static let section = "Latest collection"
    static let hint = "Save a collection on iPhone."
    static let blurb = "Your latest saved collection, egg count and carton breakdown."
    static let symbol = "shippingbox"
    static let accent = Color(red: 0.96, green: 0.78, blue: 0.42)
    static let ground = Color(red: 0.094, green: 0.235, blue: 0.188)
    static let preview = CompanionSnapshot(title: "Willow Farm", value: "37 eggs",
        detail: "3 × 10 + 1 × 7", items: [], updated: .now)
}
