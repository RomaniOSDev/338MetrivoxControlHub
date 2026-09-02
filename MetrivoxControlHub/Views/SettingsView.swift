import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("CLOSE") { dismiss() }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                Spacer()
                Text("CFG")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            LazyVGrid(columns: columns, spacing: 12) {
                hardwareKey(title: "RATE US", led: Theme.accent, action: requestReview)
                hardwareKey(title: "PRIVACY", led: Theme.primary) {
                    UIApplication.shared.open(AppLinks.privacy)
                }
                hardwareKey(title: "TERMS", led: Theme.primary) {
                    UIApplication.shared.open(AppLinks.terms)
                }
                hardwareKey(title: "RESET", led: Color.red.opacity(0.85)) {
                    confirmReset = true
                }
            }
            .padding(.horizontal, 18)

            Spacer()
        }
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
        .preferredColorScheme(.dark)
        .tint(Theme.primary)
        .confirmationDialog("Reset studio data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                store.resetAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All palettes, recents, and capture labels will be cleared.")
        }
    }

    private func hardwareKey(title: String, led: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(led)
                        .frame(width: 8, height: 8)
                        .shadow(color: led.opacity(0.85), radius: 5)
                    Spacer()
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(Theme.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Theme.neonStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
