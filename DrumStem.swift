import Foundation

struct DrumStem: Identifiable, Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case kick = "Kick"
        case snare = "Snare"
        case hats = "Hi-Hats / Cymbals"
        case percussion = "Other Percussion"

        var id: String { rawValue }
        var systemImage: String {
            switch self {
            case .kick: return "speaker.wave.2.fill"
            case .snare: return "circle.grid.cross.fill"
            case .hats: return "sparkles"
            case .percussion: return "waveform"
            }
        }
    }

    let id = UUID()
    let kind: Kind
    var outputURL: URL?
}
