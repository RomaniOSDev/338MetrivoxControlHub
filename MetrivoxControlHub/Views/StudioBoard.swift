import SwiftUI

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
