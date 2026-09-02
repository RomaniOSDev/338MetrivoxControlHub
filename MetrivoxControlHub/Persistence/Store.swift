import Foundation
import SwiftUI
import UIKit

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

@MainActor
final class Store: ObservableObject {
    @Published var savedPalettes: [Palette] = [] { didSet { persist() } }
    @Published var recentColors: [String] = [] { didSet { persist() } }
    @Published var preferredColorFormat: ColorFormat = .hex { didSet { persist() } }
    @Published var lastImageLabel: String = "" { didSet { persist() } }
    @Published var isFirstLaunch: Bool = true { didSet { persist() } }
    @Published var sampleCount: Int = 5 { didSet { persist() } }
    @Published var selectedHex: String = StudioCatalog.defaultHex
    @Published var capturedColors: [String] = []
    @Published var selectedCaptureIndex: Int = 0
    @Published var replaceCaptureOnEyedrop: Bool = false
    @Published var isSampling: Bool = false
    @Published var previewImage: UIImage?
    @Published var undoName: String?

    private var isHydrating = false
    private var undoPayload: (palette: Palette, index: Int)?
    private var undoTask: Task<Void, Never>?

    private enum Keys {
        static let savedPalettes = "savedPalettes"
        static let recentColors = "recentColors"
        static let preferredColorFormat = "preferredColorFormat"
        static let lastImageLabel = "lastImageLabel"
        static let isFirstLaunch = "isFirstLaunch"
        static let sampleCount = "sampleCount"
    }

    init() {
        hydrate()
        if isFirstLaunch {
            isFirstLaunch = false
        }
    }

    var selectedDisplay: String {
        ColorMath.displayHex(selectedHex)
    }

    func isNameAvailable(_ name: String, excluding id: UUID? = nil) -> Bool {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return false }
        return !savedPalettes.contains {
            $0.id != id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key
        }
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

    @discardableResult
    func savePalette(name: String, colors: [String], replacing id: UUID? = nil) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Enter a unique palette name." }
        guard isNameAvailable(trimmed, excluding: id) else { return "Name is already used." }
        let normalized = colors.map { ColorMath.displayHex($0) }
        guard (4...6).contains(normalized.count) else { return "Use 4 to 6 colors." }
        guard normalized.allSatisfy({ ColorMath.isValidHex($0) }) else { return "Each color must be a valid hex value." }

        let pinned = id.flatMap { paletteID in savedPalettes.first(where: { $0.id == paletteID })?.isPinned } ?? false
        let palette = Palette(id: id ?? UUID(), name: trimmed, colors: normalized, isPinned: pinned)
        if let id, let index = savedPalettes.firstIndex(where: { $0.id == id }) {
            savedPalettes[index] = palette
        } else {
            savedPalettes.insert(palette, at: 0)
        }
        recordRecents(normalized)
        if let first = normalized.first {
            selectColor(first)
        }
        return nil
    }

    func renamePalette(id: UUID, to name: String) -> String? {
        guard let palette = savedPalettes.first(where: { $0.id == id }) else { return "Palette not found." }
        return savePalette(name: name, colors: palette.colors, replacing: id)
    }

    func duplicatePalette(id: UUID) -> String? {
        guard let palette = savedPalettes.first(where: { $0.id == id }) else { return "Palette not found." }
        var copyName = palette.name + " Copy"
        var suffix = 2
        while !isNameAvailable(copyName) {
            copyName = "\(palette.name) Copy \(suffix)"
            suffix += 1
        }
        return savePalette(name: copyName, colors: palette.colors)
    }

    func togglePin(id: UUID) {
        guard let index = savedPalettes.firstIndex(where: { $0.id == id }) else { return }
        var palettes = savedPalettes
        palettes[index].isPinned.toggle()
        savedPalettes = palettes
    }

    func updatePaletteColors(id: UUID, colors: [String]) {
        guard let index = savedPalettes.firstIndex(where: { $0.id == id }) else { return }
        let normalized = colors.map { ColorMath.displayHex($0) }
        guard (4...6).contains(normalized.count), normalized.allSatisfy({ ColorMath.isValidHex($0) }) else { return }
        var palettes = savedPalettes
        palettes[index].colors = normalized
        savedPalettes = palettes
        recordRecents(normalized)
    }

    func sortPaletteByHue(id: UUID) {
        guard let palette = savedPalettes.first(where: { $0.id == id }) else { return }
        updatePaletteColors(id: id, colors: ColorMath.sortedByHue(palette.colors))
    }

    func deletePalette(id: UUID) {
        guard let index = savedPalettes.firstIndex(where: { $0.id == id }) else { return }
        let palette = savedPalettes.remove(at: index)
        undoPayload = (palette, index)
        undoName = palette.name
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
        let index = min(max(payload.index, 0), savedPalettes.count)
        savedPalettes.insert(payload.palette, at: index)
        undoPayload = nil
        undoName = nil
    }

    func ingestImage(_ image: UIImage, label: String) {
        lastImageLabel = label
        previewImage = image
        isSampling = true
        let count = min(6, max(4, sampleCount))
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

    func selectCapturedSlot(_ index: Int) {
        guard capturedColors.indices.contains(index) else { return }
        selectedCaptureIndex = index
        replaceCaptureOnEyedrop = true
        selectColor(capturedColors[index])
    }

    func applyEyedrop(_ hex: String) {
        guard ColorMath.isValidHex(hex) else { return }
        let value = ColorMath.displayHex(hex)
        selectColor(value)
        recordRecents([value])
        let limit = min(6, max(4, sampleCount))
        if capturedColors.isEmpty {
            capturedColors = [value]
            selectedCaptureIndex = 0
            replaceCaptureOnEyedrop = false
            return
        }
        if replaceCaptureOnEyedrop, capturedColors.indices.contains(selectedCaptureIndex) {
            capturedColors[selectedCaptureIndex] = value
            return
        }
        if capturedColors.count < limit {
            capturedColors.append(value)
            selectedCaptureIndex = capturedColors.count - 1
            replaceCaptureOnEyedrop = false
        } else if capturedColors.indices.contains(selectedCaptureIndex) {
            capturedColors[selectedCaptureIndex] = value
        }
    }

    func resetAll() {
        undoTask?.cancel()
        undoPayload = nil
        undoName = nil
        savedPalettes = []
        recentColors = []
        preferredColorFormat = .hex
        lastImageLabel = ""
        sampleCount = 5
        capturedColors = []
        selectedCaptureIndex = 0
        replaceCaptureOnEyedrop = false
        selectedHex = StudioCatalog.defaultHex
        isSampling = false
        previewImage = nil
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    private func applyCaptured(_ hexes: [String]) {
        capturedColors = hexes
        selectedCaptureIndex = 0
        replaceCaptureOnEyedrop = true
        if let first = hexes.first {
            selectColor(first)
        }
        recordRecents(hexes)
        isSampling = false
    }

    private func hydrate() {
        isHydrating = true
        defer { isHydrating = false }

        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.savedPalettes),
           let decoded = try? JSONDecoder().decode([Palette].self, from: data) {
            savedPalettes = decoded
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
        let storedCount = defaults.object(forKey: Keys.sampleCount) as? Int ?? 5
        sampleCount = min(6, max(4, storedCount))
        if let firstRecent = recentColors.first {
            selectedHex = firstRecent
        }
    }

    private func persist() {
        guard !isHydrating else { return }
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(savedPalettes) {
            defaults.set(data, forKey: Keys.savedPalettes)
        }
        defaults.set(recentColors, forKey: Keys.recentColors)
        defaults.set(preferredColorFormat.rawValue, forKey: Keys.preferredColorFormat)
        defaults.set(lastImageLabel, forKey: Keys.lastImageLabel)
        defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch)
        defaults.set(sampleCount, forKey: Keys.sampleCount)
    }
}
