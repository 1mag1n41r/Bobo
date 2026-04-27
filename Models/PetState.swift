import Foundation

enum PetMood: String, Codable {
    case happy, neutral, hungry, sad, sleepy
}

struct PetState: Codable {
    var hunger: Int = 80
    var happiness: Int = 80
    var energy: Int = 80

    var favorite: CropType = .berry
    var lastUpdated: Date = Date()
    var lastPatAt: Date? = nil
    var lastToyPlayAt: Date? = nil

    mutating func clamp() {
        hunger = min(100, max(0, hunger))
        happiness = min(100, max(0, happiness))
        energy = min(100, max(0, energy))
    }

    func mood() -> PetMood {
        if energy < 25 { return .sleepy }
        if hunger < 25 && happiness < 40 { return .sad }
        if hunger < 40 { return .hungry }
        if hunger >= 60 && happiness >= 60 { return .happy }
        return .neutral
    }
}
