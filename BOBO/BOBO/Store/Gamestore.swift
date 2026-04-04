import Combine
import Foundation
import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    @Published var pet: PetState
    @Published var inventory: Inventory
    @Published var garden: [GardenTile]

    let rows = 9
    let cols = 9
    private let cropFootprint = 3

    init() {
        if let save = Persistence.load() {
            self.pet = save.pet
            self.inventory = save.inventory
            self.garden = Self.normalizedGarden(from: save.garden, rows: rows, cols: cols)
        } else {
            self.pet = PetState(favorite: .berry)
            self.inventory = Inventory(items: [.corn: 1, .berry: 1, .sunflower: 1]) // starter seeds/foods
            self.garden = Array(repeating: GardenTile(), count: rows * cols)
        }
        applyOfflineProgress(now: Date())
    }

    func save() {
        Persistence.save(.init(pet: pet, inventory: inventory, garden: garden))
    }

    /// Hunger decay + energy drift based on elapsed time since lastUpdated
    func applyOfflineProgress(now: Date = Date()) {
        let elapsed = now.timeIntervalSince(pet.lastUpdated)
        guard elapsed > 1 else { return }

        // Casual decay: ~10 hunger per hour
        let hungerLossPerHour: Double = 10
        let hours = elapsed / 3600.0
        let hungerLoss = Int((hours * hungerLossPerHour).rounded(.down))

        pet.hunger -= hungerLoss

        // If very hungry, happiness drops slowly
        if pet.hunger < 30 {
            let extraSad = Int((hours * 4).rounded(.down))
            pet.happiness -= extraSad
        }

        // Energy slowly recovers when time passes (cozy)
        let energyGain = Int((hours * 3).rounded(.down))
        pet.energy += energyGain

        pet.lastUpdated = now
        pet.clamp()
        save()
    }

    // MARK: - Garden actions

    func plant(at index: Int, crop: CropType) {
        guard canPlant(at: index) else { return }

        let now = Date()
        let origin = coordinates(for: index)

        for row in origin.row..<(origin.row + cropFootprint) {
            for col in origin.col..<(origin.col + cropFootprint) {
                let tileIndex = indexFor(row: row, col: col)
                garden[tileIndex].plant(crop, originIndex: index, now: now)
            }
        }

        save()
    }

    func harvest(at index: Int) {
        guard garden.indices.contains(index) else { return }

        guard let originIndex = garden[index].originIndex else { return }
        guard garden.indices.contains(originIndex) else { return }
        guard garden[originIndex].isReady(), let crop = garden[originIndex].crop else { return }

        let origin = coordinates(for: originIndex)
        for row in origin.row..<(origin.row + cropFootprint) {
            for col in origin.col..<(origin.col + cropFootprint) {
                let tileIndex = indexFor(row: row, col: col)
                garden[tileIndex].clear()
            }
        }

        inventory.add(crop, amount: 1)
        save()
    }

    func canPlant(at index: Int) -> Bool {
        guard garden.indices.contains(index) else { return false }

        let origin = coordinates(for: index)
        guard origin.row <= rows - cropFootprint, origin.col <= cols - cropFootprint else {
            return false
        }
        guard origin.row.isMultiple(of: cropFootprint), origin.col.isMultiple(of: cropFootprint) else {
            return false
        }

        for row in origin.row..<(origin.row + cropFootprint) {
            for col in origin.col..<(origin.col + cropFootprint) {
                let tileIndex = indexFor(row: row, col: col)
                if garden[tileIndex].isPlanted() {
                    return false
                }
            }
        }

        return true
    }

    func isOriginTile(_ index: Int) -> Bool {
        guard garden.indices.contains(index) else { return false }
        return garden[index].originIndex == index
    }

    static func normalizedGarden(from savedGarden: [GardenTile], rows: Int, cols: Int) -> [GardenTile] {
        let expectedCount = rows * cols

        if savedGarden.count == expectedCount {
            return savedGarden
        }

        return Array(repeating: GardenTile(), count: expectedCount)
    }

    private func coordinates(for index: Int) -> (row: Int, col: Int) {
        (index / cols, index % cols)
    }

    private func indexFor(row: Int, col: Int) -> Int {
        row * cols + col
    }

    // MARK: - Feeding

    func feed(_ crop: CropType) -> Bool {
        applyOfflineProgress()

        guard inventory.use(crop, amount: 1) else { return false }

        // “Full” soft rule
        let isFull = pet.hunger > 85

        pet.hunger += crop.hungerGain
        pet.happiness += isFull ? 0 : crop.happinessGain

        // Favorite bonus
        if crop == pet.favorite && !isFull {
            pet.happiness += 7
        }

        pet.clamp()
        save()
        return true
    }

    func patParrot(now: Date = Date()) -> Bool {
        applyOfflineProgress(now: now)

        let cooldown: TimeInterval = 20
        if let lastPatAt = pet.lastPatAt, now.timeIntervalSince(lastPatAt) < cooldown {
            return false
        }

        pet.lastPatAt = now
        pet.happiness += pet.happiness >= 90 ? 2 : 6
        pet.energy += 1
        pet.clamp()
        save()
        return true
    }

    func playWithToy(now: Date = Date()) -> Bool {
        applyOfflineProgress(now: now)

        let cooldown: TimeInterval = 35
        if let lastToyPlayAt = pet.lastToyPlayAt, now.timeIntervalSince(lastToyPlayAt) < cooldown {
            return false
        }

        pet.lastToyPlayAt = now
        pet.happiness += 10
        pet.energy -= 4
        pet.hunger -= 2
        pet.clamp()
        save()
        return true
    }
}
