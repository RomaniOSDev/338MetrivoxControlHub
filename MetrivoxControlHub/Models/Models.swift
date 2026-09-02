import Foundation

struct Palette: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var colors: [String]
    var isPinned: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, colors, isPinned
    }

    init(id: UUID = UUID(), name: String, colors: [String], isPinned: Bool = false) {
        self.id = id
        self.name = name
        self.colors = colors
        self.isPinned = isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colors = try container.decode([String].self, forKey: .colors)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colors, forKey: .colors)
        try container.encode(isPinned, forKey: .isPinned)
    }
}

enum ColorFormat: String, Codable, CaseIterable, Identifiable {
    case hex
    case rgb

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hex: return "HEX"
        case .rgb: return "RGB"
        }
    }
}

enum StudioBoardTab: String, CaseIterable, Identifiable {
    case boards = "Boards"
    case capture = "Capture"
    case convert = "Convert"
    case stats = "Stats"

    var id: String { rawValue }
}

enum HarmonyKind: String, CaseIterable, Identifiable {
    case complementary
    case analogous
    case triadic
    case split

    var id: String { rawValue }

    var title: String {
        switch self {
        case .complementary: return "COMP"
        case .analogous: return "ANALOG"
        case .triadic: return "TRIAD"
        case .split: return "SPLIT"
        }
    }
}

enum ColorBlindMode: String, CaseIterable, Identifiable {
    case off
    case deuteranopia
    case protanopia
    case tritanopia

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "OFF"
        case .deuteranopia: return "DEUT"
        case .protanopia: return "PROT"
        case .tritanopia: return "TRIT"
        }
    }
}

struct StudioReference: Identifiable {
    let id: String
    let imageName: String
    let label: String
}

enum StudioCatalog {
    static let references: [StudioReference] = [
        StudioReference(id: "swatches", imageName: "BannerSwatches", label: "Studio Swatches"),
        StudioReference(id: "wheel", imageName: "BannerWheel", label: "Studio Wheel"),
        StudioReference(id: "sample", imageName: "BannerSample", label: "Studio Sample")
    ]

    static let defaultHex = "#E827CB"
    static let draftColors = ["#E827CB", "#5C1A6E", "#1A2852", "#F4B8EC"]
}
