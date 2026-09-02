import SwiftUI
import PhotosUI
import UIKit

struct CaptureBoard: View {
    @EnvironmentObject private var store: Store
    @State private var showPicker = false
    @State private var showSave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                importPanel
                if let previewImage = store.previewImage {
                    eyedropPanel(previewImage)
                }
                capturedPanel
                recentsPanel
                referencesPanel
            }
            .padding(16)
        }
        .sheet(isPresented: $showPicker) {
            PhotoLibraryPicker(
                onPicked: { image in
                    store.ingestImage(image, label: "Imported Photo")
                },
                onCancel: {
                    showPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSave) {
            PaletteEditor(existing: nil, initialColors: saveReadyColors)
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            showPicker = false
            showSave = false
        }
    }

    private var saveReadyColors: [String]? {
        let colors = store.capturedColors
        guard (4...6).contains(colors.count) else { return nil }
        return colors
    }

    private var importPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("CAPTURE")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                Text(store.lastImageLabel.isEmpty ? "Import a still or sample a studio reference." : store.lastImageLabel)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                HStack {
                    Text("SAMPLES")
                        .font(Theme.monoSmall)
                        .tracking(1.2)
                        .foregroundColor(Theme.accent)
                    Spacer()
                    Text("\(store.sampleCount)")
                        .font(Theme.mono)
                        .foregroundColor(Theme.primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(store.sampleCount) },
                        set: { store.sampleCount = Int($0.rounded()) }
                    ),
                    in: 4...6,
                    step: 1
                )
                .tint(Theme.primary)
                Button {
                    showPicker = true
                } label: {
                    Text("IMPORT IMAGE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                if store.isSampling {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Theme.primary)
                        Text("Sampling grid…")
                            .font(Theme.mono)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }

    private func eyedropPanel(_ image: UIImage) -> some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("EYEDROPPER")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                Text("Tap the image to fill the selected swatch.")
                    .font(Theme.mono)
                    .foregroundColor(Theme.accent.opacity(0.85))
                EyedropperCanvas(image: image) { hex in
                    store.applyEyedrop(hex)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 176)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.neonStroke, lineWidth: 1)
                )
            }
        }
    }

    private var capturedPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("EXTRACTED")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                if store.capturedColors.isEmpty {
                    Text("No sample yet. Import a photo, tap Sample, or tap a still to pick HEX.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.accent.opacity(0.85))
                } else {
                    HStack(spacing: 8) {
                        ForEach(Array(store.capturedColors.enumerated()), id: \.offset) { index, hex in
                            VStack(spacing: 6) {
                                BevelTile(
                                    hex: hex,
                                    isSelected: index == store.selectedCaptureIndex,
                                    corner: 8
                                )
                                .frame(height: 64)
                                .onTapGesture { store.selectCapturedSlot(index) }
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
                    if saveReadyColors != nil {
                        Button {
                            showSave = true
                        } label: {
                            Text("SAVE PALETTE")
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
    }

    private var recentsPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("RECENTS")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                if store.savedPalettes.isEmpty && store.recentColors.isEmpty {
                    Text("Saved palettes appear here after you store a strip.")
                        .font(Theme.mono)
                        .foregroundColor(Theme.accent.opacity(0.85))
                } else {
                    ForEach(Array(store.savedPalettes.prefix(4))) { palette in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(palette.name)
                                .font(Theme.monoSmall)
                                .foregroundColor(Theme.primary)
                            SwatchStrip(colors: palette.colors, height: 36) { hex in
                                store.selectColor(hex)
                            }
                        }
                    }
                    if !store.recentColors.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(store.recentColors.prefix(12).enumerated()), id: \.offset) { _, hex in
                                    BevelTile(hex: hex, isSelected: ColorMath.displayHex(hex) == store.selectedDisplay, corner: 8)
                                        .frame(width: 32, height: 32)
                                        .onTapGesture { store.selectColor(hex) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var referencesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STUDIO REFERENCES")
                .font(Theme.monoSmall)
                .tracking(1.6)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 4)
            ForEach(StudioCatalog.references) { reference in
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .bottomTrailing) {
                        if let image = UIImage(named: reference.imageName) {
                            EyedropperCanvas(image: image) { hex in
                                store.previewImage = image
                                store.lastImageLabel = reference.label
                                store.applyEyedrop(hex)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 132)
                        } else {
                            Image(reference.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 132)
                        }
                        Button {
                            store.sampleBundledImage(named: reference.imageName, label: reference.label)
                        } label: {
                            Text("Sample")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.background)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.neonStroke, lineWidth: 1)
                    )
                    Text(reference.label)
                        .font(Theme.mono)
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
}

struct EyedropperCanvas: UIViewRepresentable {
    let image: UIImage
    var onPick: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(image: image, onPick: onPick)
    }

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.image = image
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
        context.coordinator.image = image
        context.coordinator.onPick = onPick
    }

    final class Coordinator: NSObject {
        var image: UIImage
        var onPick: (String) -> Void

        init(image: UIImage, onPick: @escaping (String) -> Void) {
            self.image = image
            self.onPick = onPick
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let point = gesture.location(in: view)
            if let hex = ColorMath.hex(from: image, viewSize: view.bounds.size, tap: point) {
                onPick(hex)
            }
        }
    }
}

struct PhotoLibraryPicker: UIViewControllerRepresentable {
    var onPicked: (UIImage) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPicked: (UIImage) -> Void
        let onCancel: () -> Void

        init(onPicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                onCancel()
                return
            }
            onCancel()
            provider.loadObject(ofClass: UIImage.self) { [onPicked] object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    onPicked(image)
                }
            }
        }
    }
}
