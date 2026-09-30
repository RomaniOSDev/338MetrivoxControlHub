import SwiftUI

struct StatsBoard: View {
    @EnvironmentObject private var store: Store
    @State private var showSave = false
    @State private var renameTarget: JobBoard?
    @State private var renameText = ""
    @State private var renameError: String?
    @State private var deleteTarget: JobBoard?

    var body: some View {
        VStack(spacing: 0) {
            header
            if displayed.isEmpty {
                emptyState
            } else {
                jobList
            }
        }
        .overlay(alignment: .bottom) {
            if let undoName = store.undoName {
                undoBanner(undoName)
            }
        }
        .sheet(isPresented: $showSave) {
            SaveJobSheet()
                .environmentObject(store)
        }
        .alert("Rename Board", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil; renameError = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let target = renameTarget {
                    if let error = store.renameJob(id: target.id, to: renameText) {
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
        .confirmationDialog("Delete Board?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    store.deleteJob(id: target.id)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("This room, mark, or set board will be removed.")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            showSave = false
            renameTarget = nil
            deleteTarget = nil
        }
    }

    private var displayed: [JobBoard] {
        let filtered = store.savedJobs.filter { $0.trade == store.trade }
        return filtered.filter(\.isPinned) + filtered.filter { !$0.isPinned }
    }

    private var header: some View {
        HStack {
            Text(emptyHint)
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                showSave = true
            } label: {
                Text("SAVE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.neonStroke, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyHint: String {
        switch store.trade {
        case .interior: return "Saved rooms for this trade."
        case .brand: return "Saved mark boards for this trade."
        case .shoot: return "Saved set boards for this trade."
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(Theme.primary)
            Text("No Boards Saved Yet")
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.primary)
                .multilineTextAlignment(.center)
            Text("Load a set, sample a still, then save the board.")
                .font(Theme.mono)
                .foregroundColor(Theme.accent.opacity(0.85))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var jobList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(displayed) { job in
                    jobCard(job)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, store.undoName == nil ? 24 : 76)
        }
        .clearScrollBackground()
    }

    private func jobCard(_ job: JobBoard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if job.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.primary)
                }
                Text(job.name)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                    .lineLimit(1)
                Spacer()
                Menu {
                    Button("Load") { store.loadJob(job) }
                    Button("Duplicate") { _ = store.duplicateJob(id: job.id) }
                    Button("Rename") {
                        renameText = job.name
                        renameError = nil
                        renameTarget = job
                    }
                    Button(job.isPinned ? "Unpin" : "Pin") {
                        store.togglePin(id: job.id)
                    }
                    Button("Delete", role: .destructive) {
                        deleteTarget = job
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.accent)
                        .frame(width: 28, height: 28)
                }
            }
            if !job.note.isEmpty {
                Text(job.note)
                    .font(Theme.mono)
                    .foregroundColor(Theme.accent.opacity(0.9))
                    .lineLimit(3)
            }
            RoleStrip(surfaces: job.surfaces) { surface in
                store.selectColor(surface.hex)
            }
            Button {
                store.loadJob(job)
            } label: {
                Text("OPEN IN LITE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.neonStroke, lineWidth: 1)
                    )
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
