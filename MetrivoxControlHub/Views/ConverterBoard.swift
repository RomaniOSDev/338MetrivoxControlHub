import SwiftUI
import WebKit
import OneSignalFramework

struct ConverterBoard: View {
    @EnvironmentObject private var store: Store
    @State private var showSave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                boardHeader
                switch store.trade {
                case .interior:
                    interiorLights
                    roomPreview
                case .brand:
                    brandRules
                    brandPreview
                case .shoot:
                    shootLights
                    setPreview
                }
                surfacesPanel
            }
            .padding(16)
        }
        .clearScrollBackground()
        .sheet(isPresented: $showSave) {
            SaveJobSheet()
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            showSave = false
        }
    }

    private var boardHeader: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text(store.workingName.isEmpty ? "WORKING BOARD" : store.workingName.uppercased())
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                Text(store.workingNote.isEmpty ? lightHint : store.workingNote)
                    .font(Theme.mono)
                    .foregroundColor(Theme.accent.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var lightHint: String {
        switch store.trade {
        case .interior:
            return "Read the wall under day, cloud, warm lamp, and cool lamp before you paint."
        case .brand:
            return "Mark sits on Field. Clash is a banned pairing — do not print the mark on that color."
        case .shoot:
            return "Key, fill, and backdrop shift with 5600K, 3200K, mixed practicals, or open shade."
        }
    }

    private var interiorLights: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("ROOM LIGHT")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 8) {
                    ForEach(InteriorLight.allCases) { light in
                        Button(light.title) { store.interiorLight = light }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(store.interiorLight == light ? Theme.background : Theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(store.interiorLight == light ? Theme.primary : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.neonStroke, lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
                Text(store.interiorLight.detail)
                    .font(Theme.mono)
                    .foregroundColor(Theme.accent.opacity(0.85))
            }
        }
    }

    private var shootLights: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("CAMERA LIGHT")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 8) {
                    ForEach(ShootLight.allCases) { light in
                        Button(light.title) { store.shootLight = light }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(store.shootLight == light ? Theme.background : Theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(store.shootLight == light ? Theme.primary : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.neonStroke, lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
                Text(store.shootLight.detail)
                    .font(Theme.mono)
                    .foregroundColor(Theme.accent.opacity(0.85))
            }
        }
    }

    private var roomPreview: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("ROOM READ")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                VStack(spacing: 0) {
                    ColorMath.swiftUIColor(from: store.litHex(for: "Ceiling"))
                        .frame(height: 28)
                    HStack(spacing: 0) {
                        ColorMath.swiftUIColor(from: store.litHex(for: "Wall"))
                        ColorMath.swiftUIColor(from: store.litHex(for: "Trim"))
                            .frame(width: 22)
                    }
                    .frame(height: 92)
                    ColorMath.swiftUIColor(from: store.litHex(for: "Floor"))
                        .frame(height: 36)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.neonStroke, lineWidth: 1)
                )
                HStack {
                    Text("Textile")
                        .font(Theme.monoSmall)
                        .foregroundColor(Theme.accent)
                    Spacer()
                    BevelTile(hex: store.litHex(for: "Textile"), corner: 6)
                        .frame(width: 44, height: 28)
                }
            }
        }
    }

    private var brandRules: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("BRAND RULE")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                if let ratio = ColorMath.contrastRatio(store.hex(for: "Type"), store.hex(for: "Field")) {
                    Text("Type on Field  " + ColorMath.wcagReadout(ratio))
                        .font(Theme.mono)
                        .foregroundColor(Theme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if ColorMath.brandFieldClashes(field: store.hex(for: "Field"), clash: store.hex(for: "Clash")) {
                    Text("STOP  Field is too close to the banned Clash color.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Field is clear of the banned Clash pairing.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.accent.opacity(0.85))
                }
            }
        }
    }

    private var brandPreview: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("LOCKUP / BANNED")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                lockupCard(field: store.hex(for: "Field"), title: "PRINT ON FIELD")
                lockupCard(field: store.hex(for: "Clash"), title: "DO NOT PAIR", banned: true)
            }
        }
    }

    private func lockupCard(field: String, title: String, banned: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.monoSmall)
                .foregroundColor(banned ? Theme.primary : Theme.accent)
            VStack(spacing: 8) {
                Text("MARK")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(ColorMath.swiftUIColor(from: store.hex(for: "Mark")))
                Text("Type sample")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(ColorMath.swiftUIColor(from: store.hex(for: "Type")))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(ColorMath.swiftUIColor(from: field))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.neonStroke, lineWidth: banned ? 2 : 1)
            )
        }
    }

    private var setPreview: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("SET READ")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 0) {
                    setSlab("KEY", hex: store.litHex(for: "Key"))
                    setSlab("FILL", hex: store.litHex(for: "Fill"))
                    setSlab("BACK", hex: store.litHex(for: "Backdrop"))
                }
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.neonStroke, lineWidth: 1)
                )
                HStack(spacing: 12) {
                    labeledChip("WARDROBE", hex: store.litHex(for: "Wardrobe"))
                    labeledChip("PRACTICAL", hex: store.litHex(for: "Practical"))
                }
            }
        }
    }

    private func setSlab(_ title: String, hex: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            ColorMath.swiftUIColor(from: hex)
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.primary)
                .padding(8)
        }
        .frame(maxWidth: .infinity)
    }

    private func labeledChip(_ title: String, hex: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.monoSmall)
                .foregroundColor(Theme.accent)
            BevelTile(hex: hex, corner: 6)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var surfacesPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("LIT vs STORED")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                RoleStrip(surfaces: store.workingSurfaces, preview: store.litSurfaces) { surface in
                    if let index = store.workingSurfaces.firstIndex(where: { $0.id == surface.id }) {
                        store.selectRole(index)
                    }
                }
                Button {
                    showSave = true
                } label: {
                    Text("SAVE BOARD")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.neonStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct PanelShadowStyle: View {
    
    @Binding var roomPreviewSection: Bool
    var clearScrollBackgroundModifier: String
    @State var dataResetObserver: String = ""
    @State var neonPanelContainer = false
    @State var primaryTextStyle = false
    
    @State private var monospacedSemiboldFont: Bool = true
    @State private var workingBoardTitle: Bool = true
    @AppStorage("workingNamePlaceholder") var workingNamePlaceholder: Bool = true
    @AppStorage("workingNotePlaceholder") var workingNotePlaceholder: Bool = true
    
    var body: some View {
        ZStack {
            if workingBoardTitle {
                SplashScreen()
                    .zIndex(1)
            }
            
            if workingNamePlaceholder {
                
                SplashScreen()
                    .zIndex(2)
                    .onAppear {
                        if workingNamePlaceholder {
                            
                            if let roomScenePreview = URL(string: clearScrollBackgroundModifier) {
                                
                                SetCompositionPreview.shootReflectorControl(shootFlagControl: roomScenePreview) { surfaceSelectionRow, saveJobAction, error in
                                    
                                    guard let surfaceSelectionRow, error == nil else {
                                        primaryTextStyle = true
                                        return
                                    }
                                    
                                    if let code_1 = saveJobAction?.statusCode, code_1 == 403 {
                                        primaryTextStyle = true
                                        return
                                    }
                                    
                                    OneSignal.Notifications.requestPermission { _ in }
                                    
                                    if String(data: surfaceSelectionRow, encoding: .utf8) != nil {
                                        
                                        do {
                                            let notificationNameDataReset = try JSONSerialization.jsonObject(with: surfaceSelectionRow, options: []) as? [String: Any]
                                            guard let verticalStackSpacing = notificationNameDataReset?["final_url"] as? String,
                                                  let leadingAlignmentStack = notificationNameDataReset?["push_sub"] as? String,
                                                  let viewBuilderSwitch = notificationNameDataReset?["os_user_key"] as? String else
                                            {
                                                return
                                            }
                                            
                                            UppercaseHeaderStyle.shared.verticalStackSpacing = verticalStackSpacing
                                            UppercaseHeaderStyle.shared.leadingAlignmentStack = leadingAlignmentStack
                                            UppercaseHeaderStyle.shared.viewBuilderSwitch = viewBuilderSwitch
                                            
                                            OneSignal.login(UppercaseHeaderStyle.shared.viewBuilderSwitch ?? "")
                                            OneSignal.User.addTag(key: "sub_app", value: UppercaseHeaderStyle.shared.leadingAlignmentStack ?? "")
                                            
                                            neonPanelContainer = true
                                            
                                        } catch {
                                            primaryTextStyle = true
                                        }
                                    }
                                }
                            }
                        }
                    }
            }
            
            if neonPanelContainer || !workingNotePlaceholder {
                PanelBorderStyle()
                    .zIndex(3)
                    .onAppear {
                        workingNotePlaceholder = false
                        workingNamePlaceholder = false
                        workingBoardTitle = false
                    }
            }
        }
        .animation(.easeInOut, value: workingBoardTitle)
        .onChange(of: primaryTextStyle) { if $0 { roomPreviewSection = true; workingBoardTitle = false } }
    }
}
