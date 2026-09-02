import SwiftUI
import UIKit

enum Theme {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    static let hexFont = Font.system(size: 18, weight: .semibold, design: .monospaced)
    static let mono = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 11, weight: .semibold, design: .monospaced)

    static var neonStroke: LinearGradient {
        LinearGradient(
            colors: [primary, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var bevelShine: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.42),
                Color.white.opacity(0.06),
                Color.black.opacity(0.32)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct StudioCanvas: ViewModifier {
    func body(content: Content) -> some View {
        content
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
    }
}

extension View {
    func studioCanvas() -> some View {
        modifier(StudioCanvas())
    }
}

struct NeonPanel<Content: View>: View {
    var corner: CGFloat = 4
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Theme.neonStroke, lineWidth: 1)
            )
    }
}

struct BevelTile: View {
    let hex: String
    var isSelected: Bool = false
    var corner: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(ColorMath.swiftUIColor(from: hex))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.bevelShine)
                    .blendMode(.overlay)
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(isSelected ? Theme.neonStroke : LinearGradient(colors: [Color.white.opacity(0.18), Color.clear], startPoint: .top, endPoint: .bottom), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: Color.black.opacity(0.48), radius: isSelected ? 10 : 7, x: 0, y: 6)
    }
}

struct SwatchStrip: View {
    let colors: [String]
    var previewColors: [String]? = nil
    var height: CGFloat = 44
    var corner: CGFloat = 12
    var onTap: ((String) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, hex in
                ColorMath.swiftUIColor(from: shownColor(at: index, original: hex))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap?(hex)
                    }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Theme.neonStroke.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 6, y: 4)
    }

    private func shownColor(at index: Int, original: String) -> String {
        if let previewColors, previewColors.indices.contains(index) {
            return previewColors[index]
        }
        return original
    }
}

struct GradientStrip: View {
    let colors: [String]
    var height: CGFloat = 16

    var body: some View {
        let stops = colors.map { ColorMath.swiftUIColor(from: $0) }
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                LinearGradient(
                    colors: stops.count >= 2 ? stops : stops + stops,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.neonStroke.opacity(0.45), lineWidth: 1)
            )
    }
}

struct MixerPad: View {
    let title: String
    let isActive: Bool
    var ledOn: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(ledOn ? Theme.accent : Theme.primary.opacity(0.22))
                    .frame(width: 8, height: 8)
                    .shadow(color: ledOn ? Theme.accent.opacity(0.9) : Color.clear, radius: 6)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundColor(isActive ? Theme.primary : Theme.accent.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isActive ? Theme.background.opacity(0.92) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(isActive ? Theme.neonStroke : LinearGradient(colors: [Theme.accent.opacity(0.25), Theme.primary.opacity(0.2)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

struct HUDTextButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(isActive ? Theme.primary : Theme.accent.opacity(0.72))
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? Theme.background.opacity(0.85) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isActive ? Theme.neonStroke : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissInstaller())
    }
}

private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        KeyboardHostView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private final class KeyboardHostView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else { return }
        if window.gestureRecognizers?.contains(where: { $0 is KeyboardDismissTap }) == true {
            return
        }
        let tap = KeyboardDismissTap()
        tap.cancelsTouchesInView = false
        tap.delegate = tap
        window.addGestureRecognizer(tap)
    }
}

private final class KeyboardDismissTap: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    init() {
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handleTap))
    }

    @objc private func handleTap() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView {
                return false
            }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
