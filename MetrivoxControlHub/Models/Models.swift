import Foundation

enum TradeKind: String, Codable, CaseIterable, Identifiable {
    case interior
    case brand
    case shoot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interior: return "ROOM"
        case .brand: return "MARK"
        case .shoot: return "SET"
        }
    }

    var roles: [String] {
        switch self {
        case .interior: return ["Wall", "Trim", "Floor", "Ceiling", "Textile"]
        case .brand: return ["Mark", "Field", "Type", "Support", "Clash"]
        case .shoot: return ["Key", "Fill", "Backdrop", "Wardrobe", "Practical"]
        }
    }
}

enum InteriorLight: String, Codable, CaseIterable, Identifiable {
    case daylight
    case overcast
    case warmLamp
    case coolLamp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daylight: return "DAY"
        case .overcast: return "CLOUD"
        case .warmLamp: return "LAMP"
        case .coolLamp: return "COOL"
        }
    }

    var detail: String {
        switch self {
        case .daylight: return "North / clear window light"
        case .overcast: return "Soft gray daylight, less chroma"
        case .warmLamp: return "2700K practicals on plaster"
        case .coolLamp: return "4000K kitchen / bath LEDs"
        }
    }
}

enum ShootLight: String, Codable, CaseIterable, Identifiable {
    case kelvin5600
    case kelvin3200
    case mixed
    case openShade

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kelvin5600: return "5600K"
        case .kelvin3200: return "3200K"
        case .mixed: return "MIX"
        case .openShade: return "SHADE"
        }
    }

    var detail: String {
        switch self {
        case .kelvin5600: return "Daylight key, cool fill"
        case .kelvin3200: return "Tungsten interiors"
        case .mixed: return "Warm practicals vs cool window"
        case .openShade: return "Open shade, cooler wardrobe"
        }
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
    case sets = "Sets"
    case wall = "Wall"
    case lite = "Lite"
    case jobs = "Jobs"

    var id: String { rawValue }
}

struct RoleColor: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var role: String
    var hex: String

    init(id: UUID = UUID(), role: String, hex: String) {
        self.id = id
        self.role = role
        self.hex = ColorMath.displayHex(hex)
    }
}

struct JobBoard: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var trade: TradeKind
    var surfaces: [RoleColor]
    var note: String
    var interiorLight: InteriorLight
    var shootLight: ShootLight
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        name: String,
        trade: TradeKind,
        surfaces: [RoleColor],
        note: String,
        interiorLight: InteriorLight = .daylight,
        shootLight: ShootLight = .kelvin5600,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.trade = trade
        self.surfaces = surfaces
        self.note = note
        self.interiorLight = interiorLight
        self.shootLight = shootLight
        self.isPinned = isPinned
    }
}

struct CatalogScheme: Identifiable {
    let id: String
    let name: String
    let trade: TradeKind
    let useWhen: String
    let lightNote: String
    let interiorLight: InteriorLight
    let shootLight: ShootLight
    let surfaces: [RoleColor]

    init(
        id: String,
        name: String,
        trade: TradeKind,
        useWhen: String,
        lightNote: String,
        interiorLight: InteriorLight = .daylight,
        shootLight: ShootLight = .kelvin5600,
        pairs: [(String, String)]
    ) {
        self.id = id
        self.name = name
        self.trade = trade
        self.useWhen = useWhen
        self.lightNote = lightNote
        self.interiorLight = interiorLight
        self.shootLight = shootLight
        self.surfaces = pairs.map { RoleColor(id: UUID(), role: $0.0, hex: $0.1) }
    }

    func clonedSurfaces() -> [RoleColor] {
        surfaces.map { RoleColor(role: $0.role, hex: $0.hex) }
    }
}

struct PracticeStill: Identifiable {
    let id: String
    let imageName: String
    let label: String
    let trade: TradeKind
}

enum StudioCatalog {
    static let defaultHex = "#E827CB"

    static let practiceStills: [PracticeStill] = [
        PracticeStill(id: "room", imageName: "BannerSwatches", label: "Room plaster still", trade: .interior),
        PracticeStill(id: "mark", imageName: "BannerWheel", label: "Mark on paper", trade: .brand),
        PracticeStill(id: "set", imageName: "BannerSample", label: "Set still", trade: .shoot)
    ]
}

extension TradeKind {
    func lit(_ hex: String, interior: InteriorLight, shoot: ShootLight, role: String) -> String {
        switch self {
        case .interior:
            return ColorMath.applyInteriorLight(hex, interior)
        case .brand:
            return ColorMath.displayHex(hex)
        case .shoot:
            return ColorMath.applyShootLight(hex, shoot, role: role)
        }
    }
}
