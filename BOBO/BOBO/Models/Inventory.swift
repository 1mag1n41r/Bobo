import Foundation

struct Inventory: Codable {
    var items: [CropType: Int] = [:]

    mutating func add(_ crop: CropType, amount: Int = 1) {
        items[crop, default: 0] += amount
    }

    mutating func canUse(_ crop: CropType) -> Bool {
        items[crop, default: 0] > 0
    }

    mutating func use(_ crop: CropType, amount: Int = 1) -> Bool {
        let current = items[crop, default: 0]
        guard current >= amount else { return false }
        items[crop] = current - amount
        return true
    }
}
