import Foundation

enum Persistence {
    static let saveKey = "parrotfarm.save.v1"

    struct SaveData: Codable {
        var pet: PetState
        var inventory: Inventory
        var garden: [GardenTile]
    }

    static func save(_ data: SaveData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: saveKey)
        } catch {
            print("Save error:", error)
        }
    }

    static func load() -> SaveData? {
        guard let raw = UserDefaults.standard.data(forKey: saveKey) else { return nil }
        do {
            return try JSONDecoder().decode(SaveData.self, from: raw)
        } catch {
            print("Load error:", error)
            return nil
        }
    }
}
