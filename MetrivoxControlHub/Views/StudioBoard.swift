import SwiftUI
import UniformTypeIdentifiers

struct StudioBoard: View {
    @EnvironmentObject private var store: Store
    @State private var showEditor = false
    @State private var editTarget: Palette?
    @State private var renameTarget: Palette?
    @State private var renameText = ""
    @State private var renameError: String?
    @State private var deleteTarget: Palette?
    @State private var compareLeft: Palette?
    @State private var searchText = ""
    @State private var blindMode: ColorBlindMode = .off

    var body: some View {
        VStack(spacing: 0) {
            header
            if store.savedPalettes.isEmpty {
                emptyState
            } else if displayedPalettes.isEmpty {
                missingMatches
            } else {
                paletteList
            }
        }
        .overlay(alignment: .bottom) {
            if let undoName = store.undoName {
                undoBanner(undoName)
            }
        }
        .sheet(isPresented: $showEditor) {
            PaletteEditor(existing: nil, initialColors: nil)
                .environmentObject(store)
        }
        .sheet(item: $editTarget) { palette in
            PaletteEditor(existing: palette, initialColors: nil)
                .environmentObject(store)
        }
        .sheet(item: $compareLeft) { palette in
            CompareSheet(left: palette)
                .environmentObject(store)
        }
        .alert("Rename Palette", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil; renameError = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let target = renameTarget {
                    if let error = store.renamePalette(id: target.id, to: renameText) {
                        renameError = error
                        renameTarget = target
                    } else {
                        renameTarget = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                renameTarget = nil
            }
        } message: {
            Text(renameError ?? "Enter a unique name.")
        }
        .confirmationDialog("Delete Palette?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    store.deletePalette(id: target.id)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("This palette will be removed from the studio.")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            searchText = ""
            editTarget = nil
            compareLeft = nil
            blindMode = .off
        }
    }

    private var displayedPalettes: [Palette] {
        let filtered: [Palette]
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filtered = store.savedPalettes
        } else {
            filtered = store.savedPalettes.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        return filtered.filter(\.isPinned) + filtered.filter { !$0.isPinned }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Picker("Format", selection: $store.preferredColorFormat) {
                    ForEach(ColorFormat.allCases) { format in
                        Text(format.title).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Theme.primary)

                Button {
                    showEditor = true
                } label: {
                    Text("NEW")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accent)
                TextField("Search palettes", text: $searchText)
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

            Picker("CVD", selection: $blindMode) {
                ForEach(ColorBlindMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(Theme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(Theme.primary)
            Text("No Palettes Created Yet")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.primary)
                .multilineTextAlignment(.center)
            Text("Build a strip of 4–6 colors to start the board.")
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.85))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var missingMatches: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("No Palettes Match")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.primary)
            Text("Try another name or clear search.")
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.85))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var paletteList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(displayedPalettes) { palette in
                    paletteCard(palette)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, store.undoName == nil ? 24 : 76)
        }
    }

    private func paletteCard(_ palette: Palette) -> some View {
        let preview = palette.colors.map { ColorMath.simulate($0, mode: blindMode) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                if palette.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.primary)
                }
                Text(palette.name)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                    .lineLimit(1)
                Spacer()
                Menu {
                    Button("Edit") { editTarget = palette }
                    Button("Duplicate") { _ = store.duplicatePalette(id: palette.id) }
                    Button("Rename") {
                        renameText = palette.name
                        renameError = nil
                        renameTarget = palette
                    }
                    Button(palette.isPinned ? "Unpin" : "Pin") {
                        store.togglePin(id: palette.id)
                    }
                    Button("Sort Hue") { store.sortPaletteByHue(id: palette.id) }
                    if store.savedPalettes.count >= 2 {
                        Button("Compare") { compareLeft = palette }
                    }
                    Button("Delete", role: .destructive) {
                        deleteTarget = palette
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.accent)
                        .frame(width: 28, height: 28)
                }
            }
            SwatchStrip(colors: palette.colors, previewColors: preview) { hex in
                store.selectColor(hex)
            }
            GradientStrip(colors: preview)
            HStack(spacing: 8) {
                ForEach(Array(palette.colors.enumerated()), id: \.offset) { _, hex in
                    VStack(spacing: 2) {
                        Text(ColorMath.display(hex, format: store.preferredColorFormat))
                            .font(Theme.monoSmall)
                            .foregroundColor(Theme.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(ColorMath.colorName(hex))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.primary.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
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

    private func undoBanner(_ name: String) -> some View {
        HStack {
            Text("Deleted \(name)")
                .font(Theme.mono)
                .foregroundColor(Theme.primary)
                .lineLimit(1)
            Spacer()
            Button("UNDO") { store.undoDelete() }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.background)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.neonStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

struct CompareSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    let left: Palette
    @State private var rightID: UUID?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    compareBlock(left, title: "LEFT")
                    NeonPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("RIGHT")
                                .font(Theme.monoSmall)
                                .tracking(1.4)
                                .foregroundColor(Theme.accent)
                            Picker("Palette", selection: $rightID) {
                                Text("Select palette").tag(Optional<UUID>.none)
                                ForEach(otherPalettes) { palette in
                                    Text(palette.name).tag(Optional(palette.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.primary)
                        }
                    }
                    if let right {
                        compareBlock(right, title: "RIGHT")
                        similarPairs(right)
                    }
                }
                .padding(16)
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
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .tint(Theme.primary)
        .onAppear {
            rightID = otherPalettes.first?.id
        }
    }

    private var otherPalettes: [Palette] {
        store.savedPalettes.filter { $0.id != left.id }
    }

    private var right: Palette? {
        otherPalettes.first { $0.id == rightID }
    }

    private func compareBlock(_ palette: Palette, title: String) -> some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(title)  \(palette.name)")
                    .font(Theme.monoSmall)
                    .tracking(1.2)
                    .foregroundColor(Theme.accent)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    ForEach(Array(palette.colors.enumerated()), id: \.offset) { _, hex in
                        let matched = matchingHex(for: hex, in: opposite(of: palette))
                        VStack(spacing: 6) {
                            BevelTile(hex: hex, isSelected: matched != nil, corner: 8)
                                .frame(height: 48)
                            Text(ColorMath.displayHex(hex))
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundColor(matched == nil ? Theme.accent : Theme.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                GradientStrip(colors: palette.colors)
            }
        }
    }

    private func similarPairs(_ right: Palette) -> some View {
        let pairs = left.colors.compactMap { hex -> (String, String)? in
            guard let match = matchingHex(for: hex, in: right.colors) else { return nil }
            return (hex, match)
        }
        return NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("NEAR MATCHES")
                    .font(Theme.monoSmall)
                    .tracking(1.4)
                    .foregroundColor(Theme.accent)
                if pairs.isEmpty {
                    Text("No close HEX pairs between these strips.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.accent.opacity(0.85))
                } else {
                    ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                        HStack(spacing: 10) {
                            BevelTile(hex: pair.0, corner: 6)
                                .frame(width: 28, height: 28)
                            Text(ColorMath.displayHex(pair.0))
                                .font(Theme.monoSmall)
                                .foregroundColor(Theme.primary)
                            Spacer()
                            Text("≈")
                                .font(Theme.mono)
                                .foregroundColor(Theme.accent)
                            Spacer()
                            Text(ColorMath.displayHex(pair.1))
                                .font(Theme.monoSmall)
                                .foregroundColor(Theme.primary)
                            BevelTile(hex: pair.1, corner: 6)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
        }
    }

    private func opposite(of palette: Palette) -> [String] {
        if palette.id == left.id {
            return right?.colors ?? []
        }
        return left.colors
    }

    private func matchingHex(for hex: String, in candidates: [String]) -> String? {
        candidates.first { ColorMath.areSimilar(hex, $0) }
    }
}

private struct DraftSwatch: Identifiable, Equatable {
    let id: UUID
    var hex: String
}

struct PaletteEditor: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    let existing: Palette?
    let initialColors: [String]?

    @State private var name: String = ""
    @State private var swatches: [DraftSwatch] = []
    @State private var selectedID: UUID?
    @State private var draggingID: UUID?
    @State private var hexField: String = StudioCatalog.defaultHex
    @State private var hue: Double = 0.9
    @State private var saturation: Double = 0.85
    @State private var brightness: Double = 0.9
    @State private var pickerColor: Color = ColorMath.swiftUIColor(from: StudioCatalog.defaultHex)
    @State private var errorMessage: String?
    @State private var isApplying = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    NeonPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PALETTE NAME")
                                .font(Theme.monoSmall)
                                .tracking(1.4)
                                .foregroundColor(Theme.accent)
                            TextField("Midnight Magenta", text: $name)
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.primary)
                                .textInputAutocapitalization(.words)
                        }
                    }

                    NeonPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("SWATCHES  \(swatches.count)/6")
                                    .font(Theme.monoSmall)
                                    .tracking(1.2)
                                    .foregroundColor(Theme.accent)
                                Spacer()
                                Button("Add") { addColor() }
                                    .font(Theme.monoSmall)
                                    .foregroundColor(swatches.count >= 6 ? Theme.accent.opacity(0.35) : Theme.primary)
                                    .disabled(swatches.count >= 6)
                                Button("Remove") { removeColor() }
                                    .font(Theme.monoSmall)
                                    .foregroundColor(swatches.count <= 4 ? Theme.accent.opacity(0.35) : Theme.primary)
                                    .disabled(swatches.count <= 4)
                                Button("Hue") { sortHue() }
                                    .font(Theme.monoSmall)
                                    .foregroundColor(Theme.primary)
                            }
                            HStack(spacing: 8) {
                                ForEach(swatches) { swatch in
                                    BevelTile(hex: swatch.hex, isSelected: swatch.id == selectedID, corner: 10)
                                        .frame(height: 54)
                                        .onTapGesture {
                                            selectedID = swatch.id
                                            applySelection(swatch.hex)
                                        }
                                        .onDrag {
                                            draggingID = swatch.id
                                            return NSItemProvider(object: swatch.id.uuidString as NSString)
                                        }
                                        .onDrop(of: [UTType.text], delegate: SwatchDropDelegate(
                                            targetID: swatch.id,
                                            swatches: $swatches,
                                            draggingID: $draggingID
                                        ))
                                }
                            }
                            Text("Drag swatches to reorder.")
                                .font(Theme.monoSmall)
                                .foregroundColor(Theme.accent.opacity(0.8))
                            GradientStrip(colors: swatches.map(\.hex))
                        }
                    }

                    NeonPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HARMONY")
                                .font(Theme.monoSmall)
                                .tracking(1.4)
                                .foregroundColor(Theme.accent)
                            HStack(spacing: 8) {
                                ForEach(HarmonyKind.allCases) { kind in
                                    Button(kind.title) { applyHarmony(kind) }
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .stroke(Theme.neonStroke, lineWidth: 1)
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NeonPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("MIX")
                                    .font(Theme.monoSmall)
                                    .tracking(1.4)
                                    .foregroundColor(Theme.accent)
                                Spacer()
                                Text(ColorMath.colorName(currentHex))
                                    .font(Theme.monoSmall)
                                    .foregroundColor(Theme.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            HStack(spacing: 12) {
                                ColorPicker("Picker", selection: $pickerColor, supportsOpacity: false)
                                    .labelsHidden()
                                TextField("Hex", text: $hexField)
                                    .font(Theme.hexFont)
                                    .foregroundColor(Theme.primary)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .onSubmit { commitHexField() }
                                Button("SET") { commitHexField() }
                                    .font(Theme.monoSmall)
                                    .foregroundColor(Theme.primary)
                            }

                            labeledSlider("H", value: $hue, range: 0...1)
                            labeledSlider("S", value: $saturation, range: 0...1)
                            labeledSlider("B", value: $brightness, range: 0...1)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.mono)
                            .foregroundColor(Theme.primary)
                    }

                    Button {
                        save()
                    } label: {
                        Text("SAVE PALETTE")
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
            .scrollDismissesKeyboard(.immediately)
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
            .navigationTitle(existing == nil ? "New Palette" : "Edit Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.primary)
                }
            }
            .onAppear { bootstrap() }
            .onChange(of: pickerColor) { newValue in
                guard !isApplying else { return }
                write(ColorMath.hex(from: newValue))
            }
            .onChange(of: hue) { _ in commitHSB() }
            .onChange(of: saturation) { _ in commitHSB() }
            .onChange(of: brightness) { _ in commitHSB() }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .tint(Theme.primary)
        .dismissKeyboardOnTap()
    }

    private var currentHex: String {
        if let selectedID, let swatch = swatches.first(where: { $0.id == selectedID }) {
            return swatch.hex
        }
        return swatches.first?.hex ?? StudioCatalog.defaultHex
    }

    private var selectedIndex: Int {
        swatches.firstIndex(where: { $0.id == selectedID }) ?? 0
    }

    private func labeledSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(Theme.mono)
                .foregroundColor(Theme.accent)
                .frame(width: 16)
            Slider(value: value, in: range)
                .tint(Theme.primary)
        }
    }

    private func bootstrap() {
        let source: [String]
        if let existing {
            name = existing.name
            source = existing.colors
        } else if let initialColors, (4...6).contains(initialColors.count) {
            source = initialColors.map { ColorMath.displayHex($0) }
        } else {
            source = StudioCatalog.draftColors
        }
        swatches = source.map { DraftSwatch(id: UUID(), hex: ColorMath.displayHex($0)) }
        selectedID = swatches.first?.id
        applySelection(currentHex)
    }

    private func applySelection(_ hex: String) {
        isApplying = true
        hexField = ColorMath.displayHex(hex)
        pickerColor = ColorMath.swiftUIColor(from: hex)
        if let hsb = ColorMath.hsb(from: hex) {
            hue = hsb.h
            saturation = hsb.s
            brightness = hsb.b
        }
        DispatchQueue.main.async {
            isApplying = false
        }
    }

    private func commitHSB() {
        guard !isApplying else { return }
        write(ColorMath.hex(hue: hue, saturation: saturation, brightness: brightness))
    }

    private func commitHexField() {
        guard ColorMath.isValidHex(hexField) else {
            errorMessage = "Each color must be a valid hex value."
            return
        }
        errorMessage = nil
        write(ColorMath.displayHex(hexField))
        applySelection(currentHex)
    }

    private func write(_ hex: String) {
        guard swatches.indices.contains(selectedIndex) else { return }
        let value = ColorMath.displayHex(hex)
        swatches[selectedIndex].hex = value
        hexField = value
        isApplying = true
        pickerColor = ColorMath.swiftUIColor(from: value)
        if let hsb = ColorMath.hsb(from: value) {
            hue = hsb.h
            saturation = hsb.s
            brightness = hsb.b
        }
        DispatchQueue.main.async {
            isApplying = false
        }
    }

    private func addColor() {
        guard swatches.count < 6 else { return }
        let added = DraftSwatch(id: UUID(), hex: swatches.last?.hex ?? StudioCatalog.defaultHex)
        swatches.append(added)
        selectedID = added.id
        applySelection(added.hex)
    }

    private func removeColor() {
        guard swatches.count > 4, swatches.indices.contains(selectedIndex) else { return }
        swatches.remove(at: selectedIndex)
        selectedID = swatches[min(selectedIndex, swatches.count - 1)].id
        applySelection(currentHex)
    }

    private func sortHue() {
        swatches = ColorMath.sortedByHue(swatches.map(\.hex)).map { DraftSwatch(id: UUID(), hex: $0) }
        selectedID = swatches.first?.id
        applySelection(currentHex)
    }

    private func applyHarmony(_ kind: HarmonyKind) {
        let generated = ColorMath.harmony(from: currentHex, kind: kind)
        guard !generated.isEmpty else { return }
        let count = swatches.count
        var next = Array(generated.prefix(count))
        while next.count < count {
            next.append(next.last ?? StudioCatalog.defaultHex)
        }
        swatches = next.map { DraftSwatch(id: UUID(), hex: $0) }
        selectedID = swatches.first?.id
        applySelection(currentHex)
    }

    private func save() {
        if let error = store.savePalette(name: name, colors: swatches.map(\.hex), replacing: existing?.id) {
            errorMessage = error
            return
        }
        dismiss()
    }
}

private struct SwatchDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var swatches: [DraftSwatch]
    @Binding var draggingID: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggingID, draggingID != targetID,
              let from = swatches.firstIndex(where: { $0.id == draggingID }),
              let to = swatches.firstIndex(where: { $0.id == targetID }) else { return }
        withAnimation(.easeInOut(duration: 0.12)) {
            swatches.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
