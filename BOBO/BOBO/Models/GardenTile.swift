import Foundation

struct GardenTile: Codable, Identifiable {
    var id: UUID = UUID()

    var crop: CropType? = nil
    var plantedAt: Date? = nil
    var originIndex: Int? = nil

    mutating func plant(_ crop: CropType, originIndex: Int, now: Date = Date()) {
        self.crop = crop
        self.plantedAt = now
        self.originIndex = originIndex
    }

    mutating func clear() {
        self.crop = nil
        self.plantedAt = nil
        self.originIndex = nil
    }

    func isPlanted() -> Bool { originIndex != nil }

    func isReady(now: Date = Date()) -> Bool {
        guard let crop, let plantedAt else { return false }
        return now.timeIntervalSince(plantedAt) >= crop.growSeconds
    }

    func progress(now: Date = Date()) -> Double {
        guard let crop, let plantedAt else { return 0 }
        let elapsed = now.timeIntervalSince(plantedAt)
        return min(1.0, max(0.0, elapsed / crop.growSeconds))
    }
}
