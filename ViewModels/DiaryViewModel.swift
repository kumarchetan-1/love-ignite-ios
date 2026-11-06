import Combine
import SwiftUI
import UIKit

@MainActor
final class DiaryViewModel: ObservableObject {
    @Published private(set) var notes: [LoveNote] = []
    @Published private(set) var folders: [NoteFolder] = []
    @Published private(set) var insight: DiaryInsight?
    @Published var searchText = ""
    @Published var filter: DiaryFilter = .all
    @Published var dateFilter: DiaryDateFilter = .any
    @Published var isSelecting = false
    @Published var selection: Set<UUID> = []
    @Published var isAnalysing = false
    @Published var aiMessage: String?

    private var tombstones: [DiaryTombstone] = []
    private var unsaved: [UUID: LoveNote] = [:]
    private let store: DiaryStore
    private var cancellables = Set<AnyCancellable>()

    init(store: DiaryStore = .shared) {
        self.store = store
        reload()
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    var visibleNotes: [LoveNote] {
        notes
            .filter { matchesSearch($0) && matchesDate($0) && matchesFilter($0) }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned && !rhs.isPinned
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    var analysisBlocker: String? {
        let meaningful = meaningfulNotes
        if meaningful.count < 3 {
            return "Add at least 3 notes before asking for a reflection. With fewer than that, a stage would be a guess, so we won't make one."
        }
        let words = meaningful.reduce(0) { partial, note in
            partial + note.plainText.split { $0.isWhitespace || $0.isNewline }.count
        }
        if words < 40 {
            return "These notes are still very short. Add a little more before a reflection. We won't invent a stage from a few words."
        }
        return nil
    }

    var analysisWillTruncate: Bool {
        analysisPayload().truncated
    }

    func reload() {
        let snapshot = store.load()
        notes = snapshot.notes
        folders = snapshot.folders
        insight = snapshot.insight
        tombstones = snapshot.tombstones
    }

    func folder(id: UUID?) -> NoteFolder? {
        guard let id else { return nil }
        return folders.first { $0.id == id }
    }

    func note(id: UUID) -> LoveNote? {
        notes.first { $0.id == id } ?? unsaved[id]
    }

    func isPersisted(_ id: UUID) -> Bool {
        notes.contains { $0.id == id }
    }

    func document(for note: LoveNote) -> NSAttributedString {
        store.document(for: note)
    }

    func missingImageCount(for note: LoveNote, attributed: NSAttributedString) -> Int {
        store.missingImageCount(for: note, attributed: attributed)
    }

    func beginNote() -> UUID {
        let now = Date()
        let note = LoveNote(
            id: UUID(),
            title: "",
            plainText: "",
            richTextRTF: nil,
            imageFileNames: [],
            videoLinks: [],
            folderID: nil,
            isPinned: false,
            createdAt: now,
            updatedAt: now,
            syncReduced: false
        )
        unsaved[note.id] = note
        return note.id
    }

    func discardUnsaved(noteID: UUID) {
        unsaved[noteID] = nil
    }

    func save(noteID: UUID, title: String, attributed: NSAttributedString, videoLinks: [NoteVideoLink], isPinned: Bool) {
        let existing = note(id: noteID)
        let harvested = store.harvestImages(in: attributed, noteID: noteID)
        let plain = RichTextArchive.plainText(from: harvested.attributed)
        let detected = VideoLinkParser.links(in: plain)
        var links = videoLinks
        for link in detected where !links.contains(where: { $0.urlString.caseInsensitiveCompare(link.urlString) == .orderedSame }) {
            links.append(link)
        }
        let note = LoveNote(
            id: noteID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            plainText: plain,
            richTextRTF: RichTextArchive.rtfData(from: harvested.attributed),
            imageFileNames: harvested.fileNames,
            videoLinks: links,
            folderID: existing?.folderID,
            isPinned: isPinned,
            createdAt: existing?.createdAt ?? Date(),
            updatedAt: Date(),
            syncReduced: existing?.syncReduced ?? false
        )
        if let data = RichTextArchive.rtfdData(from: harvested.attributed) {
            store.writeRichText(data, noteID: noteID)
        }
        unsaved[noteID] = nil
        if let index = notes.firstIndex(where: { $0.id == noteID }) {
            notes[index] = note
        } else {
            notes.insert(note, at: 0)
        }
        persist()
    }

    func delete(ids: Set<UUID>) {
        let doomed = notes.filter { ids.contains($0.id) }
        for note in doomed {
            store.deleteImages(note.imageFileNames)
            store.deleteRichText(noteID: note.id)
            tombstones.append(DiaryTombstone(id: note.id, kind: .note, deletedAt: Date()))
        }
        notes.removeAll { ids.contains($0.id) }
        for id in ids {
            unsaved[id] = nil
        }
        selection.subtract(ids)
        if selection.isEmpty {
            isSelecting = false
        }
        persist()
    }

    func togglePin(_ id: UUID) {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isPinned.toggle()
        notes[index].updatedAt = Date()
        persist()
        Haptics.selection()
    }

    func toggleSelection(_ id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    @discardableResult
    func createFolder(name: String, colorHex: String) -> NoteFolder? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date()
        let folder = NoteFolder(
            id: UUID(),
            name: String(trimmed.prefix(40)),
            colorHex: colorHex,
            createdAt: now,
            updatedAt: now
        )
        folders.append(folder)
        persist()
        return folder
    }

    func updateFolder(id: UUID, name: String, colorHex: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        folders[index].name = String(trimmed.prefix(40))
        folders[index].colorHex = colorHex
        folders[index].updatedAt = Date()
        persist()
    }

    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        tombstones.append(DiaryTombstone(id: id, kind: .folder, deletedAt: Date()))
        for index in notes.indices where notes[index].folderID == id {
            notes[index].folderID = nil
            notes[index].updatedAt = Date()
        }
        if case .folder(let selected) = filter, selected == id {
            filter = .all
        }
        persist()
    }

    func assign(noteIDs: Set<UUID>, to folderID: UUID?) {
        guard !noteIDs.isEmpty else { return }
        for index in notes.indices where noteIDs.contains(notes[index].id) {
            notes[index].folderID = folderID
            notes[index].updatedAt = Date()
        }
        selection.removeAll()
        isSelecting = false
        persist()
    }

    func analyse() async {
        guard analysisBlocker == nil, !isAnalysing else { return }
        let payload = analysisPayload()
        isAnalysing = true
        defer { isAnalysing = false }
        do {
            let result = try await AITaskService.shared.analyseDiary(notesBlock: payload.block)
            if Task.isCancelled { return }
            guard let built = insight(from: result, noteCount: payload.count) else {
                aiMessage = "Gemini's reply couldn't be read as a reflection. Any earlier reflection is unchanged."
                return
            }
            insight = built
            aiMessage = nil
            persist()
        } catch {
            if Task.isCancelled { return }
            aiMessage = "Gemini didn't return a reflection. Your notes stayed on this device, and any earlier reflection is unchanged."
        }
    }

    func romanticSuggestion(for text: String) async -> RomanticSuggestion {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return RomanticSuggestion(text: "", usedFallback: true, notice: "Write a few words first.")
        }
        let clipped = String(trimmed.prefix(12_000))
        do {
            let reply = try await AITaskService.shared.rephraseRomantically(clipped)
            if Task.isCancelled {
                return RomanticSuggestion(text: trimmed, usedFallback: true, notice: nil)
            }
            let notice = trimmed.count > 12_000 ? "Only the first part of a very long note was sent." : nil
            return RomanticSuggestion(text: reply, usedFallback: false, notice: notice)
        } catch {
            let tidy = NoteTextCleanup.romanticTidy(trimmed)
            if tidy == trimmed {
                return RomanticSuggestion(
                    text: trimmed,
                    usedFallback: true,
                    notice: "Gemini isn't available right now. Your wording is unchanged."
                )
            }
            return RomanticSuggestion(
                text: tidy,
                usedFallback: true,
                notice: "Gemini isn't available, so this is a tidy of your own words — spacing, capitalisation, and lists only. It does not add new lines."
            )
        }
    }

    private var meaningfulNotes: [LoveNote] {
        notes.filter { note in
            let text = note.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty || !title.isEmpty
        }
    }

    private func analysisPayload() -> (block: String, truncated: Bool, count: Int) {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var parts: [String] = []
        var used = 0
        var truncated = false
        let limit = 24_000
        for note in meaningfulNotes.sorted(by: { $0.updatedAt > $1.updatedAt }) {
            let body = String(note.plainText.prefix(4_000))
            let chunk = "Date: \(formatter.string(from: note.updatedAt))\nTitle: \(note.listTitle)\n\(body)"
            if used + chunk.count > limit {
                truncated = true
                break
            }
            parts.append(chunk)
            used += chunk.count
        }
        return (parts.joined(separator: "\n\n---\n\n"), truncated, meaningfulNotes.count)
    }

    private func insight(from result: GeminiDiaryAnalysis, noteCount: Int) -> DiaryInsight? {
        if result.insufficient == true {
            return DiaryInsight(
                id: UUID(),
                generatedAt: Date(),
                insufficient: true,
                stage: "",
                explanation: "There isn't enough in these notes to suggest a stage. Add a bit more of your own words and try again. We won't guess.",
                wentWell: [],
                wentWrong: [],
                toImprove: [],
                nextActions: [],
                noteCount: noteCount,
                disclaimer: DiaryInsight.standardDisclaimer
            )
        }
        let stage = result.stage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let explanation = result.explanation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if stage.isEmpty || explanation.isEmpty {
            return nil
        }
        return DiaryInsight(
            id: UUID(),
            generatedAt: Date(),
            insufficient: false,
            stage: String(stage.prefix(80)),
            explanation: String(explanation.prefix(700)),
            wentWell: clip(result.wentWell),
            wentWrong: clip(result.wentWrong),
            toImprove: clip(result.toImprove),
            nextActions: clip(result.nextActions),
            noteCount: noteCount,
            disclaimer: DiaryInsight.standardDisclaimer
        )
    }

    private func clip(_ items: [String]?) -> [String] {
        let cleaned = (items ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(4)
            .map { String($0.prefix(280)) }
        if cleaned.isEmpty {
            return ["Nothing in these notes speaks to this directly."]
        }
        return Array(cleaned)
    }

    private func matchesFilter(_ note: LoveNote) -> Bool {
        switch filter {
        case .all, .insights:
            return true
        case .pinned:
            return note.isPinned
        case .folder(let id):
            return note.folderID == id
        }
    }

    private func matchesSearch(_ note: LoveNote) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        if note.title.localizedCaseInsensitiveContains(query) { return true }
        if note.plainText.localizedCaseInsensitiveContains(query) { return true }
        if let folder = folder(id: note.folderID), folder.name.localizedCaseInsensitiveContains(query) {
            return true
        }
        return false
    }

    private func matchesDate(_ note: LoveNote) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch dateFilter {
        case .any:
            return true
        case .week:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
            return note.updatedAt >= start
        case .month:
            guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
            return note.updatedAt >= start
        case .year:
            return calendar.component(.year, from: note.updatedAt) == calendar.component(.year, from: now)
        }
    }

    private func persist() {
        store.save(DiarySnapshot(notes: notes, folders: folders, insight: insight, tombstones: tombstones))
    }
}
