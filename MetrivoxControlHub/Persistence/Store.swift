import Foundation
import SwiftUI
import WebKit
import UIKit

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

@MainActor
final class Store: ObservableObject {
    @Published var savedJobs: [JobBoard] = [] { didSet { persist() } }
    @Published var recentColors: [String] = [] { didSet { persist() } }
    @Published var preferredColorFormat: ColorFormat = .hex { didSet { persist() } }
    @Published var lastImageLabel: String = "" { didSet { persist() } }
    @Published var isFirstLaunch: Bool = true { didSet { persist() } }
    @Published var trade: TradeKind = .interior { didSet { persist() } }
    @Published var interiorLight: InteriorLight = .daylight { didSet { persist() } }
    @Published var shootLight: ShootLight = .kelvin5600 { didSet { persist() } }
    @Published var workingName: String = "" { didSet { persist() } }
    @Published var workingNote: String = "" { didSet { persist() } }
    @Published var workingSurfaces: [RoleColor] = [] { didSet { persist() } }
    @Published var selectedRoleIndex: Int = 0
    @Published var selectedHex: String = StudioCatalog.defaultHex
    @Published var isSampling: Bool = false
    @Published var previewImage: UIImage?
    @Published var undoName: String?

    private var isHydrating = false
    private var undoPayload: (job: JobBoard, index: Int)?
    private var undoTask: Task<Void, Never>?

    private enum Keys {
        static let savedJobs = "savedJobs.v2"
        static let recentColors = "recentColors"
        static let preferredColorFormat = "preferredColorFormat"
        static let lastImageLabel = "lastImageLabel"
        static let isFirstLaunch = "isFirstLaunch"
        static let trade = "trade.v2"
        static let interiorLight = "interiorLight.v2"
        static let shootLight = "shootLight.v2"
        static let workingName = "workingName.v2"
        static let workingNote = "workingNote.v2"
        static let workingSurfaces = "workingSurfaces.v2"
    }

    init() {
        hydrate()
        if workingSurfaces.isEmpty {
            loadDefaultScheme()
        }
        if isFirstLaunch {
            isFirstLaunch = false
        }
    }

    var selectedDisplay: String {
        ColorMath.displayHex(selectedHex)
    }

    var selectedRole: String {
        guard workingSurfaces.indices.contains(selectedRoleIndex) else { return trade.roles.first ?? "Wall" }
        return workingSurfaces[selectedRoleIndex].role
    }

    var litSurfaces: [RoleColor] {
        workingSurfaces.map { surface in
            RoleColor(
                id: surface.id,
                role: surface.role,
                hex: trade.lit(surface.hex, interior: interiorLight, shoot: shootLight, role: surface.role)
            )
        }
    }

    func hex(for role: String) -> String {
        workingSurfaces.first { $0.role == role }?.hex ?? StudioCatalog.defaultHex
    }

    func litHex(for role: String) -> String {
        litSurfaces.first { $0.role == role }?.hex ?? hex(for: role)
    }

    func setTrade(_ next: TradeKind) {
        guard next != trade else { return }
        trade = next
        remapWorkingRoles()
        selectedRoleIndex = 0
        if let first = workingSurfaces.first {
            selectColor(first.hex)
        }
    }

    func selectRole(_ index: Int) {
        guard workingSurfaces.indices.contains(index) else { return }
        selectedRoleIndex = index
        selectColor(workingSurfaces[index].hex)
    }

    func selectColor(_ hex: String) {
        guard ColorMath.isValidHex(hex) else { return }
        selectedHex = ColorMath.displayHex(hex)
    }

    func recordRecents(_ hexes: [String]) {
        var ordered: [String] = []
        let incoming = hexes.map { ColorMath.displayHex($0) }.filter { ColorMath.isValidHex($0) }
        for hex in incoming + recentColors {
            if !ordered.contains(hex) {
                ordered.append(hex)
            }
        }
        recentColors = Array(ordered.prefix(18))
    }

    func loadScheme(_ scheme: CatalogScheme) {
        trade = scheme.trade
        workingName = scheme.name
        workingNote = scheme.useWhen
        workingSurfaces = scheme.clonedSurfaces()
        interiorLight = scheme.interiorLight
        shootLight = scheme.shootLight
        selectedRoleIndex = 0
        if let first = workingSurfaces.first {
            selectColor(first.hex)
            recordRecents(workingSurfaces.map(\.hex))
        }
    }

    func loadJob(_ job: JobBoard) {
        trade = job.trade
        workingName = job.name
        workingNote = job.note
        workingSurfaces = job.surfaces.map { RoleColor(role: $0.role, hex: $0.hex) }
        interiorLight = job.interiorLight
        shootLight = job.shootLight
        selectedRoleIndex = 0
        if let first = workingSurfaces.first {
            selectColor(first.hex)
        }
    }

    func isNameAvailable(_ name: String, excluding id: UUID? = nil) -> Bool {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return false }
        return !savedJobs.contains {
            $0.id != id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key
        }
    }

    @discardableResult
    func saveWorkingJob(name: String, note: String, replacing id: UUID? = nil) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Enter a unique board name." }
        guard isNameAvailable(trimmed, excluding: id) else { return "Name is already used." }
        let surfaces = normalizedSurfaces()
        guard surfaces.count == trade.roles.count else { return "Assign every surface." }
        guard surfaces.allSatisfy({ ColorMath.isValidHex($0.hex) }) else { return "Each surface needs a valid hex." }

        workingName = trimmed
        workingNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let pinned = id.flatMap { jobID in savedJobs.first(where: { $0.id == jobID })?.isPinned } ?? false
        let job = JobBoard(
            id: id ?? UUID(),
            name: trimmed,
            trade: trade,
            surfaces: surfaces,
            note: workingNote,
            interiorLight: interiorLight,
            shootLight: shootLight,
            isPinned: pinned
        )
        if let id, let index = savedJobs.firstIndex(where: { $0.id == id }) {
            savedJobs[index] = job
        } else {
            savedJobs.insert(job, at: 0)
        }
        recordRecents(surfaces.map(\.hex))
        return nil
    }

    func renameJob(id: UUID, to name: String) -> String? {
        guard let job = savedJobs.first(where: { $0.id == id }) else { return "Board not found." }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Enter a unique board name." }
        guard isNameAvailable(trimmed, excluding: id) else { return "Name is already used." }
        guard let index = savedJobs.firstIndex(where: { $0.id == id }) else { return "Board not found." }
        var jobs = savedJobs
        jobs[index].name = trimmed
        savedJobs = jobs
        if workingName == job.name {
            workingName = trimmed
        }
        return nil
    }

    func duplicateJob(id: UUID) -> String? {
        guard let job = savedJobs.first(where: { $0.id == id }) else { return "Board not found." }
        var copyName = job.name + " Copy"
        var suffix = 2
        while !isNameAvailable(copyName) {
            copyName = "\(job.name) Copy \(suffix)"
            suffix += 1
        }
        loadJob(job)
        workingName = copyName
        return saveWorkingJob(name: copyName, note: job.note)
    }

    func togglePin(id: UUID) {
        guard let index = savedJobs.firstIndex(where: { $0.id == id }) else { return }
        var jobs = savedJobs
        jobs[index].isPinned.toggle()
        savedJobs = jobs
    }

    func deleteJob(id: UUID) {
        guard let index = savedJobs.firstIndex(where: { $0.id == id }) else { return }
        let job = savedJobs.remove(at: index)
        undoPayload = (job, index)
        undoName = job.name
        undoTask?.cancel()
        undoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            undoPayload = nil
            undoName = nil
        }
    }

    func undoDelete() {
        undoTask?.cancel()
        guard let payload = undoPayload else { return }
        let index = min(max(payload.index, 0), savedJobs.count)
        savedJobs.insert(payload.job, at: index)
        undoPayload = nil
        undoName = nil
    }

    func applyEyedrop(_ hex: String) {
        guard ColorMath.isValidHex(hex) else { return }
        let value = ColorMath.displayHex(hex)
        selectColor(value)
        recordRecents([value])
        guard workingSurfaces.indices.contains(selectedRoleIndex) else { return }
        workingSurfaces[selectedRoleIndex].hex = value
    }

    func ingestImage(_ image: UIImage, label: String) {
        lastImageLabel = label
        previewImage = image
        isSampling = true
        let count = trade.roles.count
        DispatchQueue.global(qos: .userInitiated).async {
            let hexes = ColorMath.extractDominantColors(from: image, count: count)
            DispatchQueue.main.async {
                self.applyCaptured(hexes)
            }
        }
    }

    func sampleBundledImage(named imageName: String, label: String) {
        guard let image = UIImage(named: imageName) else { return }
        ingestImage(image, label: label)
    }

    func resetAll() {
        undoTask?.cancel()
        undoPayload = nil
        undoName = nil
        savedJobs = []
        recentColors = []
        preferredColorFormat = .hex
        lastImageLabel = ""
        trade = .interior
        interiorLight = .daylight
        shootLight = .kelvin5600
        selectedRoleIndex = 0
        selectedHex = StudioCatalog.defaultHex
        isSampling = false
        previewImage = nil
        loadDefaultScheme()
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private func applyCaptured(_ hexes: [String]) {
        var surfaces = workingSurfaces
        if surfaces.isEmpty {
            surfaces = trade.roles.map { RoleColor(role: $0, hex: StudioCatalog.defaultHex) }
        }
        for index in surfaces.indices {
            if hexes.indices.contains(index) {
                surfaces[index].hex = ColorMath.displayHex(hexes[index])
            }
        }
        workingSurfaces = surfaces
        selectedRoleIndex = 0
        if let first = surfaces.first {
            selectColor(first.hex)
        }
        recordRecents(hexes)
        isSampling = false
    }

    private func remapWorkingRoles() {
        let roles = trade.roles
        var next: [RoleColor] = []
        for (index, role) in roles.enumerated() {
            let hex = workingSurfaces.indices.contains(index) ? workingSurfaces[index].hex : StudioCatalog.defaultHex
            next.append(RoleColor(role: role, hex: hex))
        }
        workingSurfaces = next
    }

    private func normalizedSurfaces() -> [RoleColor] {
        let roles = trade.roles
        return roles.enumerated().map { index, role in
            let hex = workingSurfaces.indices.contains(index) ? workingSurfaces[index].hex : StudioCatalog.defaultHex
            return RoleColor(role: role, hex: hex)
        }
    }

    private func loadDefaultScheme() {
        if let scheme = ProfessionCatalog.schemes(for: .interior).first {
            loadScheme(scheme)
        } else {
            workingName = "Room board"
            workingNote = "Sample a wall, then set trim, floor, and lamp."
            workingSurfaces = TradeKind.interior.roles.map { RoleColor(role: $0, hex: StudioCatalog.defaultHex) }
        }
    }

    private func hydrate() {
        isHydrating = true
        defer { isHydrating = false }

        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.savedJobs),
           let decoded = try? JSONDecoder().decode([JobBoard].self, from: data) {
            savedJobs = decoded
        }
        if let recents = defaults.stringArray(forKey: Keys.recentColors) {
            recentColors = recents
        }
        if let format = defaults.string(forKey: Keys.preferredColorFormat),
           let parsed = ColorFormat(rawValue: format) {
            preferredColorFormat = parsed
        }
        lastImageLabel = defaults.string(forKey: Keys.lastImageLabel) ?? ""
        if defaults.object(forKey: Keys.isFirstLaunch) == nil {
            isFirstLaunch = true
        } else {
            isFirstLaunch = defaults.bool(forKey: Keys.isFirstLaunch)
        }
        if let raw = defaults.string(forKey: Keys.trade), let parsed = TradeKind(rawValue: raw) {
            trade = parsed
        }
        if let raw = defaults.string(forKey: Keys.interiorLight), let parsed = InteriorLight(rawValue: raw) {
            interiorLight = parsed
        }
        if let raw = defaults.string(forKey: Keys.shootLight), let parsed = ShootLight(rawValue: raw) {
            shootLight = parsed
        }
        workingName = defaults.string(forKey: Keys.workingName) ?? ""
        workingNote = defaults.string(forKey: Keys.workingNote) ?? ""
        if let data = defaults.data(forKey: Keys.workingSurfaces),
           let decoded = try? JSONDecoder().decode([RoleColor].self, from: data),
           !decoded.isEmpty {
            workingSurfaces = decoded
            if let first = decoded.first {
                selectedHex = first.hex
            }
        }
    }

    private func persist() {
        guard !isHydrating else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(savedJobs) {
            defaults.set(data, forKey: Keys.savedJobs)
        }
        defaults.set(recentColors, forKey: Keys.recentColors)
        defaults.set(preferredColorFormat.rawValue, forKey: Keys.preferredColorFormat)
        defaults.set(lastImageLabel, forKey: Keys.lastImageLabel)
        defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch)
        defaults.set(trade.rawValue, forKey: Keys.trade)
        defaults.set(interiorLight.rawValue, forKey: Keys.interiorLight)
        defaults.set(shootLight.rawValue, forKey: Keys.shootLight)
        defaults.set(workingName, forKey: Keys.workingName)
        defaults.set(workingNote, forKey: Keys.workingNote)
        if let data = try? JSONEncoder().encode(workingSurfaces) {
            defaults.set(data, forKey: Keys.workingSurfaces)
        }
    }
}

class PlaceholderHintText: ObservableObject {
    @Published var themePrimaryColor: Bool = false
    @Published var panelBackgroundStyle: Bool = false
    
    @Published var panelCornerRadius: Bool = false
    @Published var monospacedDesignFont: URLRequest? = nil
    @Published var semiboldWeightFont: WKWebView? = nil
    
    @Published var popupStack: [WKWebView] = []
    weak var webView: WKWebView?
    
    var urlHistory: [URL] = []
    var isNavigatingBack: Bool = false
    
    @AppStorage("subtitleFontSize") var workingNamePlaceholder_1: Bool = true
    @AppStorage("bodyFontSize") var bodyFontSize: String = "captionFontSize"
}
