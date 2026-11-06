import UIKit

/// Notes stay on this device. A text-only copy also goes through `StorageService`
/// (UserDefaults + iCloud Key-Value Storage). Photos are files in Application Support
/// because Key-Value Storage cannot hold image payloads. Nothing here is sent to the account backend.
final class DiaryStore {
    static let shared = DiaryStore()

    private let storage: StorageServiceProtocol
    private let snapshotKey = "ldiary_snapshot_v1"
    private let cloudBudget = 350_000
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let root: URL
    private let imagesDirectory: URL
    private let richDirectory: URL

    init(storage: StorageServiceProtocol = StorageService.shared) {
        self.storage = storage
        root = LocalStoreFiles.directory("LDiary")
        imagesDirectory = root.appendingPathComponent("Images", isDirectory: true)
        richDirectory = root.appendingPathComponent("Rich", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: richDirectory, withIntermediateDirectories: true)
    }

    func load() -> DiarySnapshot {
        let local = readLocal() ?? .empty
        let cloud = storage.load(DiarySnapshot.self, for: snapshotKey) ?? .empty
        let merged = merge(local: local, cloud: cloud)
        if merged != local {
            writeLocal(merged)
        }
        let slimmed = slim(merged)
        if slimmed != cloud {
            storage.save(slimmed, for: snapshotKey)
        }
        return merged
    }

    func save(_ snapshot: DiarySnapshot) {
        let normalized = normalize(snapshot)
        writeLocal(normalized)
        storage.save(slim(normalized), for: snapshotKey)
    }

    func writeRichText(_ data: Data, noteID: UUID) {
        try? data.write(to: richURL(noteID), options: .atomic)
    }

    func readRichText(noteID: UUID) -> Data? {
        try? Data(contentsOf: richURL(noteID))
    }

    func deleteRichText(noteID: UUID) {
        try? FileManager.default.removeItem(at: richURL(noteID))
    }

    func imageExists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: imageURL(fileName).path)
    }

    func loadImage(_ fileName: String) -> UIImage? {
        guard let data = try? Data(contentsOf: imageURL(fileName)) else { return nil }
        return UIImage(data: data)
    }

    func saveImage(_ image: UIImage, noteID: UUID) -> String? {
        guard let data = DiaryImageCoding.jpegData(from: image) else { return nil }
        let name = "ldi-\(noteID.uuidString)-\(UUID().uuidString).jpg"
        do {
            try data.write(to: imageURL(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    func deleteImages(_ names: [String]) {
        for name in names {
            try? FileManager.default.removeItem(at: imageURL(name))
        }
    }

    /// Copies pasted or attached images into Application Support and stamps a stable file name
    /// on the attachment so the next save does not duplicate them.
    func harvestImages(in source: NSAttributedString, noteID: UUID) -> (attributed: NSAttributedString, fileNames: [String]) {
        let mutable = NSMutableAttributedString(attributedString: source)
        var names: [String] = []
        mutable.enumerateAttribute(.attachment, in: NSRange(location: 0, length: mutable.length)) { value, _, _ in
            guard let attachment = value as? NSTextAttachment else { return }
            if let existing = attachment.fileWrapper?.preferredFilename,
               existing.hasPrefix("ldi-"),
               imageExists(existing) {
                if !names.contains(existing) {
                    names.append(existing)
                }
                return
            }
            guard let image = DiaryImageCoding.image(from: attachment),
                  let data = DiaryImageCoding.jpegData(from: image),
                  let name = writeImageData(data, noteID: noteID) else {
                return
            }
            let wrapper = FileWrapper(regularFileWithContents: data)
            wrapper.preferredFilename = name
            let existingBounds = attachment.bounds
            attachment.fileWrapper = wrapper
            if existingBounds.width > 1 {
                attachment.bounds = existingBounds
            } else {
                let width: CGFloat = 260
                let ratio = image.size.height / max(image.size.width, 1)
                attachment.bounds = CGRect(x: 0, y: 0, width: width, height: max(width * ratio, 40))
            }
            names.append(name)
        }
        return (mutable, names)
    }

    func document(for note: LoveNote) -> NSAttributedString {
        var base: NSAttributedString
        if let data = readRichText(noteID: note.id), let rich = RichTextArchive.attributedString(rtfd: data) {
            base = rich
        } else if let data = note.richTextRTF, let rich = RichTextArchive.attributedString(rtf: data) {
            base = rich
        } else {
            base = RichTextArchive.plain(note.plainText)
        }
        return appendMissingImages(to: base, fileNames: note.imageFileNames)
    }

    func missingImageCount(for note: LoveNote, attributed: NSAttributedString) -> Int {
        let present = attachmentNames(in: attributed)
        return note.imageFileNames.filter { name in
            !present.contains(name) && !imageExists(name)
        }.count
    }

    private func appendMissingImages(to source: NSAttributedString, fileNames: [String]) -> NSAttributedString {
        let present = attachmentNames(in: source)
        let mutable = NSMutableAttributedString(attributedString: source)
        for name in fileNames where !present.contains(name) {
            guard let image = loadImage(name), let data = DiaryImageCoding.jpegData(from: image) else { continue }
            if mutable.length > 0 {
                mutable.append(NSAttributedString(string: "\n", attributes: RichTextArchive.bodyAttributes))
            }
            let attachment = NSTextAttachment()
            attachment.image = image
            let width: CGFloat = 260
            let ratio = image.size.height / max(image.size.width, 1)
            attachment.bounds = CGRect(x: 0, y: 0, width: width, height: width * ratio)
            let wrapper = FileWrapper(regularFileWithContents: data)
            wrapper.preferredFilename = name
            attachment.fileWrapper = wrapper
            mutable.append(NSAttributedString(attachment: attachment))
        }
        return mutable
    }

    private func attachmentNames(in source: NSAttributedString) -> Set<String> {
        var names = Set<String>()
        source.enumerateAttribute(.attachment, in: NSRange(location: 0, length: source.length)) { value, _, _ in
            guard let attachment = value as? NSTextAttachment,
                  let name = attachment.fileWrapper?.preferredFilename else { return }
            names.insert(name)
        }
        return names
    }

    private func writeImageData(_ data: Data, noteID: UUID) -> String? {
        let name = "ldi-\(noteID.uuidString)-\(UUID().uuidString).jpg"
        do {
            try data.write(to: imageURL(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    private func richURL(_ id: UUID) -> URL {
        richDirectory.appendingPathComponent("\(id.uuidString).rtfddata")
    }

    private func imageURL(_ name: String) -> URL {
        imagesDirectory.appendingPathComponent((name as NSString).lastPathComponent)
    }

    private func readLocal() -> DiarySnapshot? {
        let url = root.appendingPathComponent("snapshot.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(DiarySnapshot.self, from: data)
    }

    private func writeLocal(_ snapshot: DiarySnapshot) {
        let url = root.appendingPathComponent("snapshot.json")
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func normalize(_ snapshot: DiarySnapshot) -> DiarySnapshot {
        var copy = snapshot
        copy.notes.sort { lhs, rhs in
            if lhs.updatedAt != rhs.updatedAt { return lhs.updatedAt > rhs.updatedAt }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        copy.folders.sort { lhs, rhs in
            let order = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if order != .orderedSame {
                return order == .orderedAscending
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        let cutoff = Date().addingTimeInterval(-180 * 24 * 60 * 60)
        copy.tombstones = copy.tombstones
            .filter { $0.deletedAt >= cutoff }
            .sorted { $0.id.uuidString < $1.id.uuidString }
        return copy
    }

    private func slim(_ snapshot: DiarySnapshot) -> DiarySnapshot {
        var copy = normalize(snapshot)
        if encodedCount(copy) <= cloudBudget {
            return copy
        }
        for index in copy.notes.indices.reversed() where copy.notes[index].richTextRTF != nil {
            copy.notes[index].richTextRTF = nil
            copy.notes[index].syncReduced = true
            if encodedCount(copy) <= cloudBudget {
                return copy
            }
        }
        for index in copy.notes.indices.reversed() where copy.notes[index].plainText.count > 280 {
            copy.notes[index].plainText = String(copy.notes[index].plainText.prefix(280))
            copy.notes[index].syncReduced = true
            if encodedCount(copy) <= cloudBudget {
                return copy
            }
        }
        return copy
    }

    private func encodedCount(_ snapshot: DiarySnapshot) -> Int {
        (try? encoder.encode(snapshot).count) ?? Int.max
    }

    private func merge(local: DiarySnapshot, cloud: DiarySnapshot) -> DiarySnapshot {
        var tombstones = local.tombstones + cloud.tombstones
        var tombstoneByID: [UUID: DiaryTombstone] = [:]
        for stone in tombstones {
            if let existing = tombstoneByID[stone.id] {
                if stone.deletedAt > existing.deletedAt {
                    tombstoneByID[stone.id] = stone
                }
            } else {
                tombstoneByID[stone.id] = stone
            }
        }
        tombstones = Array(tombstoneByID.values)

        var notesByID: [UUID: LoveNote] = [:]
        for note in local.notes + cloud.notes {
            if let existing = notesByID[note.id] {
                notesByID[note.id] = preferred(existing, note)
            } else {
                notesByID[note.id] = note
            }
        }
        let notes = notesByID.values.filter { note in
            guard let deleted = tombstoneByID[note.id], deleted.kind == .note else { return true }
            return note.updatedAt > deleted.deletedAt
        }

        var foldersByID: [UUID: NoteFolder] = [:]
        for folder in local.folders + cloud.folders {
            if let existing = foldersByID[folder.id] {
                foldersByID[folder.id] = folder.updatedAt >= existing.updatedAt ? folder : existing
            } else {
                foldersByID[folder.id] = folder
            }
        }
        let folders = foldersByID.values.filter { folder in
            guard let deleted = tombstoneByID[folder.id], deleted.kind == .folder else { return true }
            return folder.updatedAt > deleted.deletedAt
        }

        let insight = preferredInsight(local.insight, cloud.insight)
        return normalize(DiarySnapshot(
            notes: Array(notes),
            folders: Array(folders),
            insight: insight,
            tombstones: tombstones
        ))
    }

    private func preferred(_ first: LoveNote, _ second: LoveNote) -> LoveNote {
        if first.syncReduced != second.syncReduced {
            let full = first.syncReduced ? second : first
            let reduced = first.syncReduced ? first : second
            guard reduced.updatedAt > full.updatedAt else { return full }
            var merged = full
            merged.isPinned = reduced.isPinned
            merged.folderID = reduced.folderID
            merged.title = reduced.title
            merged.videoLinks = reduced.videoLinks
            merged.updatedAt = reduced.updatedAt
            return merged
        }
        let newer = first.updatedAt >= second.updatedAt ? first : second
        let older = first.updatedAt >= second.updatedAt ? second : first
        var result = newer
        if result.richTextRTF == nil {
            result.richTextRTF = older.richTextRTF
        }
        return result
    }

    private func preferredInsight(_ first: DiaryInsight?, _ second: DiaryInsight?) -> DiaryInsight? {
        switch (first, second) {
        case (nil, nil):
            return nil
        case (let insight?, nil), (nil, let insight?):
            return insight
        case (let lhs?, let rhs?):
            return lhs.generatedAt >= rhs.generatedAt ? lhs : rhs
        }
    }
}
