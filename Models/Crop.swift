import Foundation

enum CropType: String, Codable, CaseIterable, Identifiable {
    case corn
    case berry
    case sunflower

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .corn: return "玉米"
        case .berry: return "莓果"
        case .sunflower: return "葵花籽"
        }
    }

    var emoji: String {
        switch self {
        case .corn: return "🌽"
        case .berry: return "🫐"
        case .sunflower: return "🌻"
        }
    }

    /// Pixel art asset name for this crop's icon
    var iconAsset: String {
        switch self {
        case .corn: return "corn_fruit"
        case .berry: return "blueberry"
        case .sunflower: return "physalis"
        }
    }

    /// Casual timers for MVP (tune later)
    var growSeconds: TimeInterval {
        switch self {
        case .corn: return 30 * 60
        case .berry: return 45 * 60
        case .sunflower: return 60 * 60
        }
    }

    var hungerGain: Int {
        switch self {
        case .corn: return 20
        case .berry: return 25
        case .sunflower: return 30
        }
    }

    var happinessGain: Int {
        switch self {
        case .corn: return 5
        case .berry: return 8
        case .sunflower: return 10
        }
    }

    /// Returns the sprite asset name for a given growth progress (0.0–1.0)
    func spriteAsset(for progress: Double) -> String {
        let stage: Int
        switch progress {
        case ..<0.2: stage = 1
        case ..<0.4: stage = 2
        case ..<0.6: stage = 3
        case ..<0.8: stage = 4
        default: stage = 5
        }
        return "\(rawValue)_0\(stage)"
    }
}
