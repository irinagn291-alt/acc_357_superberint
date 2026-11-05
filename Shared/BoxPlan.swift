import Foundation

/// Shared limits and arithmetic for carton calculations.
struct BoxPlan: Equatable {
    let collected: Int
    let capacity: Int
    let full: Int
    let remainder: Int
    var count: Int { full + (remainder == 0 ? 0 : 1) }
    var cartons: [Int] { Array(repeating: capacity, count: full) + (remainder == 0 ? [] : [remainder]) }
    var summary: String {
        if full == 0 { return "1 × \(remainder)" }
        if remainder == 0 { return "\(full) × \(capacity)" }
        return "\(full) × \(capacity) + 1 × \(remainder)"
    }

    init?(collected: Int, capacity: Int) {
        guard (1...360).contains(collected), (1...30).contains(capacity) else { return nil }
        let full = collected / capacity
        let remainder = collected % capacity
        guard full + (remainder == 0 ? 0 : 1) <= 60 else { return nil }
        self.collected = collected
        self.capacity = capacity
        self.full = full
        self.remainder = remainder
    }
}
