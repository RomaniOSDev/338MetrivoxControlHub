import SwiftUI
import UIKit

struct ConverterBoard: View {
    @EnvironmentObject private var store: Store
    @State private var red: Double = 232
    @State private var green: Double = 39
    @State private var blue: Double = 203
    @State private var hexField: String = StudioCatalog.defaultHex
    @State private var copied = false
    @State private var isApplying = false
    @State private var clipboardHex: String?
    @State private var contrastBackground = "#1A2852"
    @State private var harmonyKind: HarmonyKind = .complementary
    @State private var showHarmonySave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                readoutPanel
                mixerPanel
                contrastPanel
                harmonyPanel
                palettesPanel
                recentsPanel
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            applyHex(store.selectedHex)
            refreshClipboard()
        }
        .onChange(of: store.selectedHex) { newValue in
            applyHex(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            copied = false
            contrastBackground = "#1A2852"
            applyHex(StudioCatalog.defaultHex)
            refreshClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            refreshClipboard()
        }
        .sheet(isPresented: $showHarmonySave) {
            PaletteEditor(existing: nil, initialColors: currentHarmony)
                .environmentObject(store)
        }
    }

    private var currentHarmony: [String] {
        let generated = ColorMath.harmony(from: store.selectedHex, kind: harmonyKind)
        if generated.count >= 4 { return Array(generated.prefix(6)) }
        return generated
    }

    private var readoutPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    BevelTile(hex: store.selectedHex, isSelected: true, corner: 16)
                        .frame(width: 92, height: 92)
                    VStack(alignment: .leading, spacing: 6) {
                        labeledValue("HEX", ColorMath.displayHex(store.selectedHex))
                        labeledValue("RGB", rgbLine)
                        labeledValue("HSB", ColorMath.hsbReadout(store.selectedHex))
                        labeledValue("NAME", ColorMath.colorName(store.selectedHex))
                    }
                }
                Button {
                    UIPasteboard.general.string = ColorMath.displayHex(store.selectedHex)
                    copied = true
                    refreshClipboard()
                } label: {
                    Text(copied ? "HEX COPIED" : "COPY HEX")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                if let clipboardHex {
                    Button {
                        store.selectColor(clipboardHex)
                        copied = false
                    } label: {
                        Text("PASTE \(clipboardHex)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(1.2)
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

    private var mixerPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("RGB ↔ HEX")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 10) {
                    TextField("#RRGGBB", text: $hexField)
                        .font(Theme.hexFont)
                        .foregroundColor(Theme.primary)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .onSubmit { commitHexField() }
                    Button("SET") { commitHexField() }
                        .font(Theme.monoSmall)
                        .foregroundColor(Theme.primary)
                }
                channelSlider("R", value: $red)
                channelSlider("G", value: $green)
                channelSlider("B", value: $blue)
            }
        }
        .onChange(of: red) { _ in commitRGB() }
        .onChange(of: green) { _ in commitRGB() }
        .onChange(of: blue) { _ in commitRGB() }
    }

    private var contrastPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("WCAG CONTRAST")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 10) {
                    contrastTile(hex: store.selectedHex, title: "FG")
                    contrastTile(hex: contrastBackground, title: "BG")
                }
                Button {
                    contrastBackground = ColorMath.displayHex(store.selectedHex)
                } label: {
                    Text("USE LIVE AS BG")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.neonStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                if let ratio = ColorMath.contrastRatio(store.selectedHex, contrastBackground) {
                    Text(ColorMath.wcagReadout(ratio))
                        .font(Theme.mono)
                        .foregroundColor(Theme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Ag")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(ColorMath.swiftUIColor(from: store.selectedHex))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(ColorMath.swiftUIColor(from: contrastBackground))
                        )
                }
                Text("Long-press a recent or saved swatch to set background.")
                    .font(Theme.monoSmall)
                    .foregroundColor(Theme.accent.opacity(0.85))
            }
        }
    }

    private var harmonyPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("HARMONY")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 8) {
                    ForEach(HarmonyKind.allCases) { kind in
                        Button(kind.title) { harmonyKind = kind }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(harmonyKind == kind ? Theme.background : Theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(harmonyKind == kind ? Theme.primary : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.neonStroke, lineWidth: 1)
                            )
                    }
                }
                .buttonStyle(.plain)
                SwatchStrip(colors: currentHarmony, height: 42) { hex in
                    store.selectColor(hex)
                    copied = false
                }
                GradientStrip(colors: currentHarmony)
                Button {
                    showHarmonySave = true
                } label: {
                    Text("SAVE HARMONY")
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
                .disabled(currentHarmony.count < 4)
            }
        }
    }

    private var palettesPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("SAVED STRIPS")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                if store.savedPalettes.isEmpty {
                    Text("Tap a saved palette color to load HEX, RGB, and HSB.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.accent.opacity(0.85))
                } else {
                    ForEach(store.savedPalettes) { palette in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(palette.name)
                                .font(Theme.monoSmall)
                                .foregroundColor(Theme.primary)
                            SwatchStrip(colors: palette.colors, height: 42) { hex in
                                store.selectColor(hex)
                                copied = false
                            }
                            .onLongPressGesture {
                                contrastBackground = palette.colors.first.map { ColorMath.displayHex($0) } ?? contrastBackground
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentsPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("RECENTS")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                if store.recentColors.isEmpty {
                    Text("Captured and saved colors land here. Tap to load, long-press to set contrast BG.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.accent.opacity(0.85))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(store.recentColors.prefix(12).enumerated()), id: \.offset) { _, hex in
                                BevelTile(hex: hex, isSelected: ColorMath.displayHex(hex) == store.selectedDisplay, corner: 8)
                                    .frame(width: 36, height: 36)
                                    .onTapGesture {
                                        store.selectColor(hex)
                                        copied = false
                                    }
                                    .onLongPressGesture {
                                        contrastBackground = ColorMath.displayHex(hex)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private func contrastTile(hex: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.monoSmall)
                .foregroundColor(Theme.accent)
            BevelTile(hex: hex, corner: 8)
                .frame(height: 44)
            Text(ColorMath.displayHex(hex))
                .font(Theme.monoSmall)
                .foregroundColor(Theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rgbLine: String {
        guard let rgb = ColorMath.rgbComponents(from: store.selectedHex) else { return "—" }
        return "\(rgb.r), \(rgb.g), \(rgb.b)"
    }

    private func labeledValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.monoSmall)
                .tracking(1.2)
                .foregroundColor(Theme.accent)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func channelSlider(_ title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(Theme.mono)
                .foregroundColor(Theme.accent)
                .frame(width: 16)
            Slider(value: value, in: 0...255, step: 1)
                .tint(Theme.primary)
            Text("\(Int(value.wrappedValue))")
                .font(Theme.mono)
                .foregroundColor(Theme.primary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func applyHex(_ hex: String) {
        guard ColorMath.isValidHex(hex), let rgb = ColorMath.rgbComponents(from: hex) else { return }
        isApplying = true
        hexField = ColorMath.displayHex(hex)
        red = Double(rgb.r)
        green = Double(rgb.g)
        blue = Double(rgb.b)
        DispatchQueue.main.async {
            isApplying = false
        }
    }

    private func commitRGB() {
        guard !isApplying else { return }
        let hex = ColorMath.hex(r: Int(red), g: Int(green), b: Int(blue))
        hexField = hex
        store.selectColor(hex)
        copied = false
    }

    private func commitHexField() {
        guard ColorMath.isValidHex(hexField) else { return }
        store.selectColor(hexField)
        applyHex(hexField)
        copied = false
    }

    private func refreshClipboard() {
        let pasted = ColorMath.hexFromPasteboard()
        if pasted == ColorMath.displayHex(store.selectedHex) {
            clipboardHex = nil
        } else {
            clipboardHex = pasted
        }
    }
}
