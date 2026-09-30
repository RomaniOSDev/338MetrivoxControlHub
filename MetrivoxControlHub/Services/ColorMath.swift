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

    static func mix(_ hex: String, with tint: String, amount: Double) -> String {
        guard let a = rgbComponents(from: hex), let b = rgbComponents(from: tint) else { return displayHex(hex) }
        let t = min(max(amount, 0), 1)
        return Self.hex(
            r: Int((Double(a.r) * (1 - t) + Double(b.r) * t).rounded()),
            g: Int((Double(a.g) * (1 - t) + Double(b.g) * t).rounded()),
            b: Int((Double(a.b) * (1 - t) + Double(b.b) * t).rounded())
        )
    }

    static func shiftBrightness(_ hex: String, factor: Double) -> String {
        guard let hsb = hsb(from: hex) else { return displayHex(hex) }
        return Self.hex(hue: hsb.h, saturation: hsb.s, brightness: min(max(hsb.b * factor, 0.08), 1))
    }

    static func applyInteriorLight(_ hex: String, _ light: InteriorLight) -> String {
        switch light {
        case .daylight:
            return shiftBrightness(mix(hex, with: "#E8F2FF", amount: 0.08), factor: 1.06)
        case .overcast:
            return shiftBrightness(mix(hex, with: "#C5D0DC", amount: 0.16), factor: 0.88)
        case .warmLamp:
            return shiftBrightness(mix(hex, with: "#FFB060", amount: 0.2), factor: 0.92)
        case .coolLamp:
            return shiftBrightness(mix(hex, with: "#A8D8FF", amount: 0.14), factor: 1.04)
        }
    }

    static func applyShootLight(_ hex: String, _ light: ShootLight, role: String) -> String {
        switch light {
        case .kelvin5600:
            return mix(hex, with: "#E8F2FF", amount: 0.1)
        case .kelvin3200:
            return mix(hex, with: "#FFB060", amount: 0.22)
        case .mixed:
            if role == "Fill" || role == "Backdrop" {
                return mix(hex, with: "#A8D8FF", amount: 0.16)
            }
            return mix(hex, with: "#FFB060", amount: 0.2)
        case .openShade:
            return shiftBrightness(mix(hex, with: "#9BB8D8", amount: 0.18), factor: 0.9)
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

    static func brandFieldClashes(field: String, clash: String) -> Bool {
        areSimilar(field, clash, threshold: 72)
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
