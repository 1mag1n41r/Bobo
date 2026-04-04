import Foundation

enum CropType: String, Codable, CaseIterable, Identifiable {
    case corn
    case berry
    case sunflower

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .corn: return "Corn"
        case .berry: return "Berry"
        case .sunflower: return "Sunflower Seeds"
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
}
