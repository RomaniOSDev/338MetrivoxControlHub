import SwiftUI
import UIKit

enum ColorMath {
    static func normalize(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        return value
    }

    static func isValidHex(_ raw: String) -> Bool {
        let hex = normalize(raw)
        guard hex.count == 6 else { return false }
        return hex.allSatisfy { $0.isHexDigit }
    }

    static func displayHex(_ raw: String) -> String {
        let hex = normalize(raw)
        guard hex.count == 6 else { return raw.uppercased() }
        return "#" + hex
    }

    static func rgbComponents(from hex: String) -> (r: Int, g: Int, b: Int)? {
        let value = normalize(hex)
        guard value.count == 6, let packed = Int(value, radix: 16) else { return nil }
        return ((packed >> 16) & 0xFF, (packed >> 8) & 0xFF, packed & 0xFF)
    }

    static func hex(r: Int, g: Int, b: Int) -> String {
        let red = min(255, max(0, r))
        let green = min(255, max(0, g))
        let blue = min(255, max(0, b))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    static func hex(hue: Double, saturation: Double, brightness: Double) -> String {
        let color = UIColor(
            hue: CGFloat(min(max(hue, 0), 1)),
            saturation: CGFloat(min(max(saturation, 0), 1)),
            brightness: CGFloat(min(max(brightness, 0), 1)),
            alpha: 1
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return hex(r: Int((red * 255).rounded()), g: Int((green * 255).rounded()), b: Int((blue * 255).rounded()))
    }

    static func hex(from color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return hex(r: Int((red * 255).rounded()), g: Int((green * 255).rounded()), b: Int((blue * 255).rounded()))
    }

    static func swiftUIColor(from hex: String) -> Color {
        guard let rgb = rgbComponents(from: hex) else {
            return Color("AppSurface")
        }
        return Color(
            red: Double(rgb.r) / 255.0,
            green: Double(rgb.g) / 255.0,
            blue: Double(rgb.b) / 255.0
        )
    }

    static func hsb(from hex: String) -> (h: Double, s: Double, b: Double)? {
        guard let rgb = rgbComponents(from: hex) else { return nil }
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(
            red: CGFloat(rgb.r) / 255.0,
            green: CGFloat(rgb.g) / 255.0,
            blue: CGFloat(rgb.b) / 255.0,
            alpha: 1
        ).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (Double(hue), Double(saturation), Double(brightness))
    }

    static func display(_ hex: String, format: ColorFormat) -> String {
        switch format {
        case .hex:
            return displayHex(hex)
        case .rgb:
            guard let rgb = rgbComponents(from: hex) else { return displayHex(hex) }
            return "\(rgb.r), \(rgb.g), \(rgb.b)"
        }
    }

    static func hsbReadout(_ hex: String) -> String {
        guard let hsb = hsb(from: hex) else { return "—" }
        let hue = Int((hsb.h * 360).rounded())
        let sat = Int((hsb.s * 100).rounded())
        let bri = Int((hsb.b * 100).rounded())
        return "H \(hue)  S \(sat)%  B \(bri)%"
    }

    static func colorName(_ hex: String) -> String {
        guard let rgb = rgbComponents(from: hex) else { return "Unknown" }
        var best = "Unknown"
        var bestDist = Int.max
        for (name, namedHex) in namedCatalog {
            guard let named = rgbComponents(from: namedHex) else { continue }
            let dist = abs(named.r - rgb.r) + abs(named.g - rgb.g) + abs(named.b - rgb.b)
            if dist < bestDist {
                bestDist = dist
                best = name
            }
        }
        return best
    }

    static func hexFromPasteboard() -> String? {
        guard let raw = UIPasteboard.general.string else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidHex(trimmed) { return displayHex(trimmed) }
        let compact = trimmed.replacingOccurrences(of: " ", with: "")
        if let match = compact.range(of: "#[0-9A-Fa-f]{6}", options: .regularExpression) {
            let value = String(compact[match])
            if isValidHex(value) { return displayHex(value) }
        }
        if compact.count == 6, isValidHex(compact) {
            return displayHex(compact)
        }
        return nil
    }

    static func wrapHue(_ value: Double) -> Double {
        let folded = value.truncatingRemainder(dividingBy: 1)
        return folded < 0 ? folded + 1 : folded
    }

    static func harmony(from hex: String, kind: HarmonyKind) -> [String] {
        guard let hsb = hsb(from: hex) else { return [] }
        let hue = hsb.h
        let sat = max(0.18, hsb.s)
        let bri = max(0.22, hsb.b)
        switch kind {
        case .complementary:
            return [
                Self.hex(hue: hue, saturation: sat, brightness: bri),
                Self.hex(hue: hue, saturation: sat, brightness: max(0.22, bri - 0.18)),
                Self.hex(hue: wrapHue(hue + 0.5), saturation: sat, brightness: bri),
                Self.hex(hue: wrapHue(hue + 0.5), saturation: min(1, sat + 0.08), brightness: max(0.2, bri - 0.12)),
                Self.hex(hue: wrapHue(hue + 0.5), saturation: max(0.2, sat - 0.18), brightness: min(1, bri + 0.08))
            ]
        case .analogous:
            return [-2, -1, 0, 1, 2].map { step in
                Self.hex(hue: wrapHue(hue + Double(step) * (30.0 / 360.0)), saturation: sat, brightness: bri)
            }
        case .triadic:
            return [
                Self.hex(hue: hue, saturation: sat, brightness: bri),
                Self.hex(hue: wrapHue(hue + 1.0 / 3.0), saturation: sat, brightness: bri),
                Self.hex(hue: wrapHue(hue + 2.0 / 3.0), saturation: sat, brightness: bri),
                Self.hex(hue: hue, saturation: sat, brightness: max(0.22, bri - 0.18)),
                Self.hex(hue: wrapHue(hue + 1.0 / 3.0), saturation: max(0.2, sat - 0.12), brightness: min(1, bri + 0.06))
            ]
        case .split:
            return [
                Self.hex(hue: hue, saturation: sat, brightness: bri),
                Self.hex(hue: wrapHue(hue + 0.5 - 1.0 / 12.0), saturation: sat, brightness: bri),
                Self.hex(hue: wrapHue(hue + 0.5 + 1.0 / 12.0), saturation: sat, brightness: bri),
                Self.hex(hue: wrapHue(hue + 0.5 - 1.0 / 12.0), saturation: sat, brightness: max(0.22, bri - 0.16)),
                Self.hex(hue: wrapHue(hue + 0.5 + 1.0 / 12.0), saturation: max(0.2, sat - 0.14), brightness: bri)
            ]
        }
    }

    static func sortedByHue(_ hexes: [String]) -> [String] {
        hexes.sorted { left, right in
            let leftHSB = hsb(from: left)
            let rightHSB = hsb(from: right)
            let leftHue = leftHSB?.h ?? 0
            let rightHue = rightHSB?.h ?? 0
            if abs(leftHue - rightHue) < 0.0008 {
                return (leftHSB?.s ?? 0) > (rightHSB?.s ?? 0)
            }
            return leftHue < rightHue
        }
    }

    static func relativeLuminance(from hex: String) -> Double? {
        guard let rgb = rgbComponents(from: hex) else { return nil }
        func channel(_ value: Int) -> Double {
            let scaled = Double(value) / 255.0
            return scaled <= 0.03928 ? scaled / 12.92 : pow((scaled + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.r) + 0.7152 * channel(rgb.g) + 0.0722 * channel(rgb.b)
    }

    static func contrastRatio(_ foreground: String, _ background: String) -> Double? {
        guard let first = relativeLuminance(from: foreground),
              let second = relativeLuminance(from: background) else { return nil }
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func wcagReadout(_ ratio: Double) -> String {
        let aa = ratio >= 4.5 ? "PASS" : "FAIL"
        let aaa = ratio >= 7 ? "PASS" : "FAIL"
        let large = ratio >= 3 ? "PASS" : "FAIL"
        return String(format: "%.1f:1  AA %@  AAA %@  LARGE %@", ratio, aa, aaa, large)
    }

    static func areSimilar(_ left: String, _ right: String, threshold: Int = 56) -> Bool {
        guard let a = rgbComponents(from: left), let b = rgbComponents(from: right) else { return false }
        return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) < threshold
    }

    static func simulate(_ hex: String, mode: ColorBlindMode) -> String {
        guard mode != .off, let rgb = rgbComponents(from: hex) else { return displayHex(hex) }
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0
        let mapped: (Double, Double, Double)
        switch mode {
        case .off:
            mapped = (r, g, b)
        case .protanopia:
            mapped = (0.56667 * r + 0.43333 * g, 0.55833 * r + 0.44167 * g, 0.24167 * g + 0.75833 * b)
        case .deuteranopia:
            mapped = (0.625 * r + 0.375 * g, 0.7 * r + 0.3 * g, 0.3 * g + 0.7 * b)
        case .tritanopia:
            mapped = (0.95 * r + 0.05 * g, 0.433 * g + 0.567 * b, 0.475 * g + 0.525 * b)
        }
        return Self.hex(
            r: Int((min(max(mapped.0, 0), 1) * 255).rounded()),
            g: Int((min(max(mapped.1, 0), 1) * 255).rounded()),
            b: Int((min(max(mapped.2, 0), 1) * 255).rounded())
        )
    }

    static func hex(from image: UIImage, viewSize: CGSize, tap: CGPoint) -> String? {
        guard let cgImage = orientedCGImage(from: image), viewSize.width > 1, viewSize.height > 1 else { return nil }
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }
        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let drawn = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: (viewSize.width - drawn.width) / 2, y: (viewSize.height - drawn.height) / 2)
        let imagePoint = CGPoint(x: (tap.x - origin.x) / scale, y: (tap.y - origin.y) / scale)
        guard imagePoint.x >= 0, imagePoint.y >= 0, imagePoint.x < imageSize.width, imagePoint.y < imageSize.height else {
            return nil
        }
        let pixelX = min(max(Int((imagePoint.x / imageSize.width) * CGFloat(cgImage.width)), 0), cgImage.width - 1)
        let pixelY = min(max(Int((imagePoint.y / imageSize.height) * CGFloat(cgImage.height)), 0), cgImage.height - 1)
        var pixel = [UInt8](repeating: 0, count: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let sampled = pixel.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return false }
            context.interpolationQuality = .none
            context.translateBy(x: -CGFloat(pixelX), y: -CGFloat(pixelY))
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            return true
        }
        guard sampled else { return nil }
        return hex(r: Int(pixel[0]), g: Int(pixel[1]), b: Int(pixel[2]))
    }

    private static let namedCatalog: [(String, String)] = [
        ("Black", "#000000"), ("Charcoal", "#2B2B2B"), ("Slate", "#4A5568"), ("Gray", "#808080"),
        ("Silver", "#C0C0C0"), ("White", "#FFFFFF"), ("Ivory", "#FFFFF0"), ("Beige", "#F5F5DC"),
        ("Brown", "#8B4513"), ("Tan", "#D2B48C"), ("Maroon", "#800000"), ("Crimson", "#DC143C"),
        ("Red", "#E32636"), ("Coral", "#FF7F50"), ("Salmon", "#FA8072"), ("Orange", "#FF8C00"),
        ("Amber", "#FFBF00"), ("Gold", "#FFD700"), ("Yellow", "#F4D03F"), ("Lime", "#B4E645"),
        ("Olive", "#808000"), ("Green", "#2ECC71"), ("Mint", "#98FF98"), ("Teal", "#008080"),
        ("Cyan", "#1ABC9C"), ("Sky", "#5DADE2"), ("Azure", "#007FFF"), ("Blue", "#2E5BFF"),
        ("Navy", "#1A2852"), ("Indigo", "#4B0082"), ("Violet", "#7F00FF"), ("Purple", "#6C2BD9"),
        ("Magenta", "#E827CB"), ("Fuchsia", "#FF00FF"), ("Pink", "#F4B8EC"), ("Rose", "#FF66CC"),
        ("Lavender", "#B57EDC"), ("Plum", "#5C1A6E"), ("Wine", "#5C1A33"), ("Peach", "#FFCBA4")
    ]

    static func extractDominantColors(from image: UIImage, count: Int = 5) -> [String] {
        guard count > 0, let cgImage = orientedCGImage(from: image) else { return [] }

        let maxSide = 80
        let sourceWidth = cgImage.width
        let sourceHeight = cgImage.height
        let scale = min(CGFloat(maxSide) / CGFloat(max(sourceWidth, 1)), CGFloat(maxSide) / CGFloat(max(sourceHeight, 1)), 1)
        let width = max(1, Int((CGFloat(sourceWidth) * scale).rounded()))
        let height = max(1, Int((CGFloat(sourceHeight) * scale).rounded()))
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let drew = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return false }
            context.interpolationQuality = .low
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { return [] }

        var buckets: [UInt32: Int] = [:]
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let index = (y * width + x) * 4
                let red = pixels[index]
                let green = pixels[index + 1]
                let blue = pixels[index + 2]
                let alpha = pixels[index + 3]
                if alpha < 28 { continue }
                let quantizedRed = UInt32(red / 17) * 17
                let quantizedGreen = UInt32(green / 17) * 17
                let quantizedBlue = UInt32(blue / 17) * 17
                let key = (quantizedRed << 16) | (quantizedGreen << 8) | quantizedBlue
                buckets[key, default: 0] += 1
            }
        }

        let ranked = buckets.sorted { $0.value > $1.value }
        var picked: [String] = []
        var pickedRGB: [(Int, Int, Int)] = []
        func append(red: Int, green: Int, blue: Int, minDistance: Int) {
            if picked.count >= count { return }
            if pickedRGB.contains(where: { abs($0.0 - red) + abs($0.1 - green) + abs($0.2 - blue) < minDistance }) {
                return
            }
            pickedRGB.append((red, green, blue))
            picked.append(hex(r: red, g: green, b: blue))
        }
        for (key, _) in ranked {
            let red = Int((key >> 16) & 0xFF)
            let green = Int((key >> 8) & 0xFF)
            let blue = Int(key & 0xFF)
            append(red: red, green: green, blue: blue, minDistance: 48)
        }
        if picked.count < count {
            for (key, _) in ranked {
                let red = Int((key >> 16) & 0xFF)
                let green = Int((key >> 8) & 0xFF)
                let blue = Int(key & 0xFF)
                append(red: red, green: green, blue: blue, minDistance: 1)
            }
        }
        return picked
    }

    private static func orientedCGImage(from image: UIImage) -> CGImage? {
        if image.imageOrientation == .up, let cgImage = image.cgImage {
            return cgImage
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return rendered.cgImage
    }
}
