import SwiftUI

struct ContentView: View {
    @StateObject private var store = Store()
    @State private var board: StudioBoardTab = .boards
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            liveReadout
            Group {
                switch board {
                case .boards:
                    StudioBoard()
                case .capture:
                    CaptureBoard()
                case .convert:
                    ConverterBoard()
                case .stats:
                    StatsBoard()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            mixerDeck
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
        .dismissKeyboardOnTap()
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            board = .boards
            showSettings = false
        }
    }

    private var liveReadout: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 7, height: 7)
                .shadow(color: Theme.accent.opacity(0.9), radius: 5)
            Text("LIVE")
                .font(Theme.monoSmall)
                .tracking(2)
                .foregroundColor(Theme.accent)
            Text(store.selectedDisplay)
                .font(Theme.hexFont)
                .foregroundColor(Theme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(ColorMath.colorName(store.selectedHex))
                .font(Theme.monoSmall)
                .foregroundColor(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface.opacity(0.94))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.neonStroke)
                .frame(height: 2)
        }
    }

    private var mixerDeck: some View {
        HStack(spacing: 8) {
            ForEach(StudioBoardTab.allCases) { tab in
                MixerPad(title: tab.rawValue.uppercased(), isActive: board == tab, ledOn: board == tab) {
                    board = tab
                }
            }
            MixerPad(title: "CFG", isActive: false, ledOn: false) {
                showSettings = true
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(Theme.surface.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.neonStroke)
                .frame(height: 2)
        }
    }
}
