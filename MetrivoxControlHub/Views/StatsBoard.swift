import Charts
import SwiftUI

struct StatsBoard: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        if isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryRow
                    if !hueBuckets.isEmpty {
                        hueChart
                    }
                    if !paletteTones.isEmpty {
                        toneChart
                    }
                    if !brightnessBands.isEmpty {
                        brightnessChart
                    }
                    if !channelMix.isEmpty {
                        rgbChart
                    }
                    if !lengthBuckets.isEmpty {
                        lengthChart
                    }
                }
                .padding(16)
            }
        }
    }

    private var isEmpty: Bool {
        store.savedPalettes.isEmpty && store.recentColors.isEmpty && store.capturedColors.isEmpty
    }

    private var analysisColors: [String] {
        let saved = store.savedPalettes.flatMap(\.colors)
        if !saved.isEmpty { return saved }
        return store.recentColors + store.capturedColors
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(Theme.primary)
            Text("No Studio Data Yet")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.primary)
                .multilineTextAlignment(.center)
            Text("Save palettes or capture colors to plot hue, tone, and mix.")
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.85))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            summaryTile("PAL", value: "\(store.savedPalettes.count)")
            summaryTile("SWATCH", value: "\(store.savedPalettes.flatMap(\.colors).count)")
            summaryTile("RECENT", value: "\(store.recentColors.count)")
            summaryTile("CAP", value: "\(store.capturedColors.count)")
        }
    }

    private func summaryTile(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.monoSmall)
                .tracking(1.2)
                .foregroundColor(Theme.accent)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Theme.neonStroke, lineWidth: 1)
        )
    }

    private var hueChart: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("HUE FAMILIES", detail: dominantFamily)
                Chart(hueBuckets) { bucket in
                    BarMark(
                        x: .value("Family", bucket.label),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(bucket.tint)
                    .cornerRadius(3)
                }
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Theme.accent.opacity(0.22))
                        AxisValueLabel().foregroundStyle(Theme.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Theme.primary)
                    }
                }
                .frame(height: 176)
            }
        }
    }

    private var toneChart: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("PALETTE TONE", detail: "AVG BRIGHTNESS")
                Chart(paletteTones) { tone in
                    LineMark(
                        x: .value("Palette", tone.index),
                        y: .value("Brightness", tone.brightness)
                    )
                    .foregroundStyle(Theme.primary)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Palette", tone.index),
                        y: .value("Brightness", tone.brightness)
                    )
                    .foregroundStyle(Theme.accent)
                }
                .chartYScale(domain: 0...100)
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 50, 100]) { _ in
                        AxisGridLine().foregroundStyle(Theme.accent.opacity(0.22))
                        AxisValueLabel().foregroundStyle(Theme.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: paletteTones.map(\.index)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self) {
                                Text("#\(index)")
                                    .foregroundColor(Theme.primary)
                            }
                        }
                    }
                }
                .frame(height: 176)
            }
        }
    }

    private var brightnessChart: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("BRIGHTNESS", detail: "DARK / MID / BRIGHT")
                Chart(brightnessBands) { band in
                    BarMark(
                        x: .value("Band", band.label),
                        y: .value("Count", band.count)
                    )
                    .foregroundStyle(band.tint)
                    .cornerRadius(3)
                }
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Theme.accent.opacity(0.22))
                        AxisValueLabel().foregroundStyle(Theme.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Theme.primary)
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private var rgbChart: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("RGB MIX", detail: "AVERAGE CHANNEL")
                Chart(channelMix) { channel in
                    BarMark(
                        x: .value("Channel", channel.label),
                        y: .value("Value", channel.value)
                    )
                    .foregroundStyle(channel.tint)
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...255)
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 128, 255]) { _ in
                        AxisGridLine().foregroundStyle(Theme.accent.opacity(0.22))
                        AxisValueLabel().foregroundStyle(Theme.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Theme.primary)
                    }
                }
                .frame(height: 160)
            }
        }
    }

    private var lengthChart: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                chartHeader("STRIP LENGTH", detail: "4 / 5 / 6 SWATCHES")
                Chart(lengthBuckets) { bucket in
                    BarMark(
                        x: .value("Length", bucket.label),
                        y: .value("Palettes", bucket.count)
                    )
                    .foregroundStyle(Theme.primary)
                    .cornerRadius(3)
                }
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Theme.accent.opacity(0.22))
                        AxisValueLabel().foregroundStyle(Theme.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Theme.primary)
                    }
                }
                .frame(height: 148)
            }
        }
    }

    private func chartHeader(_ title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.monoSmall)
                .tracking(1.6)
                .foregroundColor(Theme.accent)
            Spacer()
            Text(detail)
                .font(Theme.monoSmall)
                .foregroundColor(Theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var dominantFamily: String {
        hueBuckets.max(by: { $0.count < $1.count })?.label ?? "—"
    }

    private var hueBuckets: [StatBucket] {
        var counts: [HueFamily: Int] = [:]
        for hex in analysisColors {
            guard let hsb = ColorMath.hsb(from: hex) else { continue }
            counts[HueFamily.from(hsb: hsb), default: 0] += 1
        }
        return HueFamily.allCases.compactMap { family in
            let count = counts[family] ?? 0
            guard count > 0 else { return nil }
            return StatBucket(id: "hue-\(family.rawValue)", label: family.label, count: count, tint: family.tint)
        }
    }

    private var paletteTones: [PaletteTone] {
        store.savedPalettes.enumerated().compactMap { index, palette in
            let values = palette.colors.compactMap { ColorMath.hsb(from: $0)?.b }
            guard !values.isEmpty else { return nil }
            let average = values.reduce(0, +) / Double(values.count)
            return PaletteTone(id: palette.id, index: index + 1, brightness: Int((average * 100).rounded()))
        }
    }

    private var brightnessBands: [StatBucket] {
        var dark = 0
        var mid = 0
        var bright = 0
        for hex in analysisColors {
            guard let brightness = ColorMath.hsb(from: hex)?.b else { continue }
            if brightness < 0.34 {
                dark += 1
            } else if brightness < 0.67 {
                mid += 1
            } else {
                bright += 1
            }
        }
        return [
            StatBucket(id: "bri-dark", label: "DARK", count: dark, tint: Color.white.opacity(0.28)),
            StatBucket(id: "bri-mid", label: "MID", count: mid, tint: Theme.accent),
            StatBucket(id: "bri-bright", label: "BRIGHT", count: bright, tint: Theme.primary)
        ].filter { $0.count > 0 }
    }

    private var channelMix: [ChannelMix] {
        let rgbs = analysisColors.compactMap { ColorMath.rgbComponents(from: $0) }
        guard !rgbs.isEmpty else { return [] }
        let count = Double(rgbs.count)
        let red = Double(rgbs.reduce(0) { $0 + $1.r }) / count
        let green = Double(rgbs.reduce(0) { $0 + $1.g }) / count
        let blue = Double(rgbs.reduce(0) { $0 + $1.b }) / count
        return [
            ChannelMix(id: "rgb-r", label: "R", value: red, tint: Color.red.opacity(0.85)),
            ChannelMix(id: "rgb-g", label: "G", value: green, tint: Color.green.opacity(0.85)),
            ChannelMix(id: "rgb-b", label: "B", value: blue, tint: Color.blue.opacity(0.85))
        ]
    }

    private var lengthBuckets: [StatBucket] {
        guard !store.savedPalettes.isEmpty else { return [] }
        var counts = [4: 0, 5: 0, 6: 0]
        for palette in store.savedPalettes {
            let length = min(6, max(4, palette.colors.count))
            counts[length, default: 0] += 1
        }
        return [4, 5, 6].compactMap { length in
            let count = counts[length] ?? 0
            guard count > 0 else { return nil }
            return StatBucket(id: "len-\(length)", label: "\(length)", count: count, tint: Theme.primary)
        }
    }
}

private struct StatBucket: Identifiable {
    let id: String
    let label: String
    let count: Int
    let tint: Color
}

private struct PaletteTone: Identifiable {
    let id: UUID
    let index: Int
    let brightness: Int
}

private struct ChannelMix: Identifiable {
    let id: String
    let label: String
    let value: Double
    let tint: Color
}

private enum HueFamily: String, CaseIterable {
    case red, orange, yellow, green, cyan, blue, magenta, neutral

    var label: String {
        switch self {
        case .red: return "RED"
        case .orange: return "ORG"
        case .yellow: return "YLW"
        case .green: return "GRN"
        case .cyan: return "CYN"
        case .blue: return "BLU"
        case .magenta: return "MAG"
        case .neutral: return "NEU"
        }
    }

    var tint: Color {
        switch self {
        case .red: return Color(red: 0.92, green: 0.22, blue: 0.28)
        case .orange: return Color(red: 0.96, green: 0.52, blue: 0.18)
        case .yellow: return Color(red: 0.95, green: 0.84, blue: 0.22)
        case .green: return Color(red: 0.22, green: 0.78, blue: 0.42)
        case .cyan: return Color(red: 0.18, green: 0.78, blue: 0.86)
        case .blue: return Color(red: 0.24, green: 0.42, blue: 0.96)
        case .magenta: return Color(red: 0.91, green: 0.16, blue: 0.80)
        case .neutral: return Color.white.opacity(0.45)
        }
    }

    static func from(hsb: (h: Double, s: Double, b: Double)) -> HueFamily {
        if hsb.s < 0.08 { return .neutral }
        let degrees = hsb.h * 360
        switch degrees {
        case 0..<15, 345...360: return .red
        case 15..<45: return .orange
        case 45..<75: return .yellow
        case 75..<165: return .green
        case 165..<195: return .cyan
        case 195..<255: return .blue
        default: return .magenta
        }
    }
}
