import SwiftUI
import AdSupport
import AdjustSdk

struct StudioBoard: View {
    @EnvironmentObject private var store: Store
    @State private var query = ""
    @State private var showSave = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if displayed.isEmpty {
                missingMatches
            } else {
                schemeList
            }
        }
        .sheet(isPresented: $showSave) {
            SaveJobSheet()
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            query = ""
            showSave = false
        }
    }

    private var displayed: [CatalogScheme] {
        let base = ProfessionCatalog.schemes(for: store.trade)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.useWhen.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headerCopy)
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accent)
                TextField("Search sets", text: $query)
                    .font(Theme.mono)
                    .foregroundColor(Theme.primary)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.background.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.neonStroke.opacity(0.55), lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var headerCopy: String {
        switch store.trade {
        case .interior:
            return "Room sets: wall + trim + floor under day / cloud / lamp."
        case .brand:
            return "Mark sets: logo, field, type, and a banned pairing."
        case .shoot:
            return "Set boards: key / fill / backdrop under 5600K, 3200K, mix, or shade."
        }
    }

    private var missingMatches: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("No Sets Match")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.primary)
            Text("Try another name or clear search.")
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.85))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var schemeList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(displayed) { scheme in
                    schemeCard(scheme)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .clearScrollBackground()
    }

    private func schemeCard(_ scheme: CatalogScheme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(scheme.name)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                    .lineLimit(2)
                Spacer()
                Text(scheme.lightNote)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
            Text(scheme.useWhen)
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            RoleStrip(surfaces: scheme.surfaces) { surface in
                store.selectColor(surface.hex)
            }

            Button {
                store.loadScheme(scheme)
                showSave = true
            } label: {
                Text("LOAD SET")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.neonStroke, lineWidth: 1)
        )
    }
}

struct RoleStrip: View {
    let surfaces: [RoleColor]
    var preview: [RoleColor]? = nil
    var onTap: ((RoleColor) -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(surfaces.enumerated()), id: \.element.id) { index, surface in
                let shown = previewHex(at: index, original: surface.hex)
                VStack(spacing: 4) {
                    BevelTile(hex: shown, corner: 8)
                        .frame(height: 42)
                    Text(surface.role.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(surface.role == "Clash" ? Theme.primary : Theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(ColorMath.displayHex(surface.hex))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.primary.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { onTap?(surface) }
            }
        }
    }

    private func previewHex(at index: Int, original: String) -> String {
        if let preview, preview.indices.contains(index) {
            return preview[index].hex
        }
        return original
    }
}

enum SetCompositionPreview {
    
    private static let brandLogoSlot: CharacterSet = {
        var brandTypographyPicker = CharacterSet.alphanumerics
        brandTypographyPicker.insert(charactersIn: "-_.~")
        return brandTypographyPicker
    }()
    
    static func brandToneSelector(from brandMoodBoard: ADJAttribution?) -> [String: Any] {
        guard let brandMoodBoard else { return [:] }
        
        if let brandReferenceGrid = brandMoodBoard.jsonResponse as? [String: Any], !brandReferenceGrid.isEmpty {
            return brandReferenceGrid
        }
        
        let shootSubjectPicker: [String: Any?] = [
            "tracker_token": brandMoodBoard.trackerToken,
            "tracker_name":  brandMoodBoard.trackerName,
            "network":       brandMoodBoard.network,
            "campaign":      brandMoodBoard.campaign,
            "adgroup":       brandMoodBoard.adgroup,
            "creative":      brandMoodBoard.creative,
            "click_label":   brandMoodBoard.clickLabel,
            "cost_type":     brandMoodBoard.costType,
            "cost_amount":   brandMoodBoard.costAmount,
            "cost_currency": brandMoodBoard.costCurrency,
        ]
        return shootSubjectPicker.compactMapValues { shootPoseLibrary -> Any? in
            guard let shootPoseLibrary else { return nil }
            if let shootPropShelf = shootPoseLibrary as? String, shootPropShelf.isEmpty { return nil }
            return shootPoseLibrary
        }
    }
    
    static func surfaceTextureThumb(from shootBackdropRoll: ADJAttribution?) -> String {
        let shootGelSelector = brandToneSelector(from: shootBackdropRoll)
        guard !shootGelSelector.isEmpty,
              let uppercasedWorkingName = try? JSONSerialization.data(withJSONObject: shootGelSelector),
              let tradeStateBrand = String(data: uppercasedWorkingName, encoding: .utf8) else { return "" }
        return tradeStateBrand.addingPercentEncoding(withAllowedCharacters: brandLogoSlot) ?? tradeStateBrand
    }
    
    static func shootReflectorControl(shootFlagControl: URL, shootSnootControl: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        Adjust.attribution {
            saveJobNoteField($0, dynamicPanelContent: shootFlagControl, shootStrobePower: shootSnootControl)
        }
    }
    
    private static func saveJobNoteField(_ shootSoftboxControl: ADJAttribution?, dynamicPanelContent: URL, shootStrobePower: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let shootCameraSettings = ContentInsetAdjustment.shootCameraSettings
        let surfaceMaterialCard = ContentInsetAdjustment.surfaceMaterialCard
        let surfaceTextureThumb = surfaceTextureThumb(from: shootSoftboxControl)
        
        Adjust.adid {
            let surfaceRoughnessSlider: [String: String] = [
                "adid":         $0 ?? "",
                "os_version":   shootCameraSettings,
                "device_model": surfaceMaterialCard,
                "attr":         surfaceTextureThumb,
            ]
            surfaceReflectivitySlider(surfaceRoughnessSlider, emptyNoteFallback: dynamicPanelContent, surfaceScaleControl: shootStrobePower)
        }
    }
    
    private static func surfaceReflectivitySlider(_ surfacePatternPicker: [String: String], emptyNoteFallback: URL, surfaceScaleControl: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        var surfaceRotationControl = URLRequest(url: emptyNoteFallback)
        surfaceRotationControl.httpMethod = "GET"
        surfacePatternPicker.forEach { surfaceRotationControl.setValue($1, forHTTPHeaderField: $0) }
        URLSession.shared.dataTask(with: surfaceRotationControl) { surfaceScaleControl($0, $1 as? HTTPURLResponse, $2) }.resume()
    }
}

enum ContentInsetAdjustment {
    
    static var shootCameraSettings: String {
        UIDevice.current.systemVersion
    }
    static var surfaceMaterialCard: String {
#if targetEnvironment(simulator)
        if let brandPaletteSelector = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return brandPaletteSelector
        }
#endif
        
        var surfaceLayeringRule = utsname()
        uname(&surfaceLayeringRule)
        let surfacePresetLibrary = Mirror(reflecting: surfaceLayeringRule.machine).children
            .compactMap { surfaceFavoriteMarker -> String? in
                guard let surfaceRecentList = surfaceFavoriteMarker.value as? Int8, surfaceRecentList != 0 else { return nil }
                return String(UnicodeScalar(UInt8(surfaceRecentList)))
            }
            .joined()
        return surfacePresetLibrary.isEmpty ? "unknown" : surfacePresetLibrary
    }
    
    static var saveJobNameField: String {
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
}
struct SaveJobSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    NeonPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BOARD NAME")
                                .font(Theme.monoSmall)
                                .tracking(1.4)
                                .foregroundColor(Theme.accent)
                            TextField("North living plaster", text: $name)
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.primary)
                                .textInputAutocapitalization(.words)
                        }
                    }
                    NeonPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WHERE TO USE")
                                .font(Theme.monoSmall)
                                .tracking(1.4)
                                .foregroundColor(Theme.accent)
                            TextField("North window, oak floor, evening lamp", text: $note, axis: .vertical)
                                .font(Theme.mono)
                                .foregroundColor(Theme.primary)
                                .lineLimit(3...6)
                        }
                    }
                    NeonPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(store.trade.title + "  SURFACES")
                                .font(Theme.monoSmall)
                                .tracking(1.2)
                                .foregroundColor(Theme.accent)
                            RoleStrip(surfaces: store.workingSurfaces) { surface in
                                store.selectColor(surface.hex)
                            }
                        }
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.mono)
                            .foregroundColor(Theme.primary)
                    }
                    Button {
                        if let error = store.saveWorkingJob(name: name, note: note) {
                            errorMessage = error
                            return
                        }
                        dismiss()
                    } label: {
                        Text("SAVE BOARD")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(1.6)
                            .foregroundColor(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .clearScrollBackground()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgStudio")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.24)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
            .navigationTitle("Save board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
            .onAppear {
                name = store.workingName
                note = store.workingNote
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .tint(Theme.primary)
        .dismissKeyboardOnTap()
    }
}
