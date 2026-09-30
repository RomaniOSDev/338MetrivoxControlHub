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
                rolesPanel
                stillsPanel
            }
            .padding(16)
        }
        .clearScrollBackground()
        .sheet(isPresented: $showPicker) {
            PhotoLibraryPicker(
                onPicked: { image in
                    store.ingestImage(image, label: pickerLabel)
                },
                onCancel: {
                    showPicker = false
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSave) {
            SaveJobSheet()
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            showPicker = false
            showSave = false
        }
    }

    private var pickerLabel: String {
        switch store.trade {
        case .interior: return "Wall still"
        case .brand: return "Mark still"
        case .shoot: return "Set still"
        }
    }

    private var importPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text(store.trade == .interior ? "WALL SAMPLE" : store.trade == .brand ? "MARK SAMPLE" : "SET SAMPLE")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                Text(store.lastImageLabel.isEmpty ? sampleHint : store.lastImageLabel)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Selected surface: \(store.selectedRole)")
                    .font(Theme.mono)
                    .foregroundColor(Theme.accent.opacity(0.85))
                Button {
                    showPicker = true
                } label: {
                    Text(store.trade == .interior ? "IMPORT ROOM PHOTO" : store.trade == .brand ? "IMPORT LOCKUP" : "IMPORT SET STILL")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.2)
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
                        Text("Reading surfaces…")
                            .font(Theme.mono)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }

    private var sampleHint: String {
        switch store.trade {
        case .interior:
            return "Photograph the wall next to trim and floor. Tap to fill the selected surface."
        case .brand:
            return "Photograph a lockup or printed mark. Tap to fill Mark, Field, or Clash."
        case .shoot:
            return "Photograph the set. Tap to fill Key, Fill, Backdrop, Wardrobe, or Practical."
        }
    }

    private func eyedropPanel(_ image: UIImage) -> some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("TAP TO FILL \(store.selectedRole.uppercased())")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                Text("Pick a role below, then tap the still.")
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

    private var rolesPanel: some View {
        NeonPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("SURFACES")
                    .font(Theme.monoSmall)
                    .tracking(1.6)
                    .foregroundColor(Theme.accent)
                HStack(spacing: 8) {
                    ForEach(Array(store.workingSurfaces.enumerated()), id: \.element.id) { index, surface in
                        VStack(spacing: 6) {
                            BevelTile(
                                hex: surface.hex,
                                isSelected: index == store.selectedRoleIndex,
                                corner: 8
                            )
                            .frame(height: 56)
                            .onTapGesture { store.selectRole(index) }
                            Text(surface.role.uppercased())
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(surface.role == "Clash" ? Theme.primary : Theme.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                            Text(ColorMath.display(surface.hex, format: store.preferredColorFormat))
                                .font(Theme.monoSmall)
                                .foregroundColor(Theme.accent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                Button {
                    showSave = true
                } label: {
                    Text("SAVE BOARD")
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

    private var stillsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRACTICE STILLS")
                .font(Theme.monoSmall)
                .tracking(1.6)
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 4)
            ForEach(StudioCatalog.practiceStills.filter { $0.trade == store.trade }) { still in
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .bottomTrailing) {
                        if let image = UIImage(named: still.imageName) {
                            EyedropperCanvas(image: image) { hex in
                                store.previewImage = image
                                store.lastImageLabel = still.label
                                store.applyEyedrop(hex)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 132)
                        }
                        Button {
                            store.sampleBundledImage(named: still.imageName, label: still.label)
                        } label: {
                            Text("Read")
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
                    Text(still.label)
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
