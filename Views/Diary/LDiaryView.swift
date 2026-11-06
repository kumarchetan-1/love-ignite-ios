import SwiftUI

struct LDiaryView: View {
    @EnvironmentObject private var diary: DiaryViewModel
    @Environment(\.colorScheme) private var scheme
    @State private var path = NavigationPath()
    @State private var showInsightConsent = false
    @State private var showAssign = false
    @State private var showNewFolder = false
    @State private var folderDraft: NoteFolder?
    @State private var folderPendingDelete: NoteFolder?
    @State private var confirmDeleteNotes = false

    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    searchRow
                    filterRow
                    if diary.filter == .insights {
                        DiaryInsightSection { showInsightConsent = true }
                    } else {
                        if diary.filter == .all {
                            DiaryInsightSection { showInsightConsent = true }
                        }
                        notesSection
                    }
                    Text("Notes are kept on this device and in iCloud key-value storage. Photos stay on the device that added them.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    Spacer().frame(height: diary.isSelecting ? 180 : 120)
                }
                .padding(.horizontal, isIPad ? 36 : 16)
                .padding(.top, isIPad ? 36 : 64)
            }
            .navigationDestination(for: UUID.self) { id in
                NoteEditorView(noteID: id)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .overlay(alignment: .bottom) {
            if diary.isSelecting {
                selectionBar
                    .padding(.horizontal, isIPad ? 36 : 16)
                    .padding(.bottom, 108)
            }
        }
        .sheet(isPresented: $showInsightConsent) {
            InsightConsentSheet().environmentObject(diary)
        }
        .sheet(isPresented: $showAssign) {
            AssignFolderSheet(noteIDs: diary.selection).environmentObject(diary)
        }
        .sheet(isPresented: $showNewFolder) {
            FolderDraftSheet(heading: "New folder", name: "", colorHex: DiaryPalette.folderSwatches[0].hex) { name, hex in
                if let folder = diary.createFolder(name: name, colorHex: hex) {
                    diary.filter = .folder(folder.id)
                }
            }
        }
        .sheet(item: $folderDraft) { folder in
            FolderDraftSheet(heading: "Edit folder", name: folder.name, colorHex: folder.colorHex) { name, hex in
                diary.updateFolder(id: folder.id, name: name, colorHex: hex)
            }
        }
        .alert("Delete this folder?", isPresented: Binding(
            get: { folderPendingDelete != nil },
            set: { if !$0 { folderPendingDelete = nil } }
        )) {
            Button("Delete folder", role: .destructive) {
                if let folder = folderPendingDelete {
                    diary.deleteFolder(id: folder.id)
                }
                folderPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { folderPendingDelete = nil }
        } message: {
            Text("Notes in the folder stay in LDiary. They just won't be grouped anymore.")
        }
        .alert("Delete selected notes?", isPresented: $confirmDeleteNotes) {
            Button("Delete", role: .destructive) {
                diary.delete(ids: diary.selection)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the notes from this device. The deletion also syncs through iCloud key-value storage.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LDiary")
                    .font(.system(size: isIPad ? 40 : 32, weight: .black, design: .rounded))
                    .foregroundColor(scheme == .dark ? .white : ThemePalette.neonPurple)
                Text("Your love, written down")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
            Spacer()
            HStack(spacing: 8) {
                Button(diary.isSelecting ? "Done" : "Select") {
                    diary.isSelecting.toggle()
                    if !diary.isSelecting { diary.selection.removeAll() }
                    Haptics.selection()
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                Button {
                    showNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("New folder")
                Button {
                    path.append(diary.beginNote())
                } label: {
                    Image(systemName: "square.and.pencil")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("New note")
            }
            .foregroundColor(ThemePalette.primaryText(for: scheme))
        }
    }

    private var searchRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
            TextField("Search notes", text: $diary.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Menu {
                ForEach(DiaryDateFilter.allCases) { filter in
                    Button {
                        diary.dateFilter = filter
                    } label: {
                        if diary.dateFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            } label: {
                Image(systemName: "calendar")
                    .foregroundColor(diary.dateFilter == .any ? ThemePalette.secondaryText(for: scheme) : ThemePalette.neonGreen)
            }
            .accessibilityLabel("Filter by date, \(diary.dateFilter.rawValue)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .neonCard(cornerRadius: 16)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", selected: diary.filter == .all) { diary.filter = .all }
                filterChip("Pinned", selected: diary.filter == .pinned) { diary.filter = .pinned }
                filterChip("Insights", selected: diary.filter == .insights) { diary.filter = .insights }
                ForEach(diary.folders) { folder in
                    filterChip(folder.name, color: HexColor.color(folder.colorHex), selected: diary.filter == .folder(folder.id)) {
                        diary.filter = .folder(folder.id)
                    }
                    .contextMenu {
                        Button("Rename and recolour") { folderDraft = folder }
                        Button("Delete folder", role: .destructive) { folderPendingDelete = folder }
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, color: Color? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { action() }
            Haptics.selection()
        } label: {
            HStack(spacing: 6) {
                if let color {
                    Circle().fill(color).frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(selected ? .white : ThemePalette.primaryText(for: scheme))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule().fill(selected ? ThemePalette.neonPurple : Color.white.opacity(scheme == .dark ? 0.08 : 0.45))
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var notesSection: some View {
        if diary.visibleNotes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(diary.notes.isEmpty ? "No notes yet" : "Nothing matches")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(diary.notes.isEmpty
                     ? "Start with a small note — a sentence, a photo, a link you want to keep."
                     : "Try another folder, date, or search.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .neonCard()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(diary.visibleNotes) { note in
                    NoteCard(
                        note: note,
                        folder: diary.folder(id: note.folderID),
                        selected: diary.selection.contains(note.id),
                        selecting: diary.isSelecting
                    ) {
                        if diary.isSelecting {
                            diary.toggleSelection(note.id)
                        } else {
                            path.append(note.id)
                        }
                    }
                    .contextMenu {
                        Button(note.isPinned ? "Unpin" : "Pin") { diary.togglePin(note.id) }
                        Button("Select") {
                            diary.isSelecting = true
                            diary.toggleSelection(note.id)
                        }
                        Button("Delete", role: .destructive) { diary.delete(ids: [note.id]) }
                    }
                }
            }
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Text("\(diary.selection.count) selected")
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Spacer()
            Button("Add to folder") { showAssign = true }
                .disabled(diary.selection.isEmpty)
            Button("Delete") { confirmDeleteNotes = true }
                .disabled(diary.selection.isEmpty)
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundColor(ThemePalette.primaryText(for: scheme))
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .neonCard(cornerRadius: 18)
    }
}

private struct NoteCard: View {
    let note: LoveNote
    let folder: NoteFolder?
    let selected: Bool
    let selecting: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                if selecting {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selected ? ThemePalette.neonGreen : ThemePalette.secondaryText(for: scheme))
                        .padding(.top, 2)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        if let folder {
                            Circle().fill(HexColor.color(folder.colorHex)).frame(width: 8, height: 8)
                            Text(folder.name)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(HexColor.color(folder.colorHex))
                        }
                        Spacer()
                        if note.isPinned {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(ThemePalette.neonGreen)
                                .accessibilityLabel("Pinned")
                        }
                    }
                    Text(note.listTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(ThemePalette.primaryText(for: scheme))
                        .multilineTextAlignment(.leading)
                    if !note.excerpt.isEmpty {
                        Text(note.excerpt)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(ThemePalette.secondaryText(for: scheme))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    HStack(spacing: 8) {
                        Text(note.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        if !note.imageFileNames.isEmpty {
                            Label("\(note.imageFileNames.count)", systemImage: "photo")
                        }
                        if !note.videoLinks.isEmpty {
                            Label("\(note.videoLinks.count)", systemImage: "play.rectangle")
                        }
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .neonCard()
        }
        .buttonStyle(.plain)
    }
}
