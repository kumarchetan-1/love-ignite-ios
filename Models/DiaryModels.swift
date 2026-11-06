import Foundation

struct LoveNote: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var plainText: String
    /// RTF without image bytes so formatting can travel through iCloud Key-Value Storage.
    var richTextRTF: Data?
    var imageFileNames: [String]
    var videoLinks: [NoteVideoLink]
    var folderID: UUID?
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date
    /// True on the cloud copy when rich text or body text was shortened to fit Key-Value Storage.
    var syncReduced: Bool

    var listTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        let firstLine = plainText.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let cleaned = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled note" : cleaned
    }

    var excerpt: String {
        let flat = plainText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if flat.count <= 160 {
            return flat
        }
        return String(flat.prefix(157)) + "…"
    }
}

struct NoteVideoLink: Identifiable, Codable, Equatable {
    var id: UUID
    var urlString: String
    var platform: VideoPlatform
    var title: String

    var url: URL? { URL(string: urlString) }
}

enum VideoPlatform: String, Codable, Equatable {
    case youtube
    case instagram
    case other

    var label: String {
        switch self {
        case .youtube:
            return "YouTube"
        case .instagram:
            return "Instagram Reel"
        case .other:
            return "Video"
        }
    }

    var systemImage: String {
        switch self {
        case .youtube:
            return "play.rectangle.fill"
        case .instagram:
            return "film.fill"
        case .other:
            return "link"
        }
    }
}

struct NoteFolder: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var updatedAt: Date
}

struct DiaryTombstone: Codable, Equatable, Identifiable {
    var id: UUID
    var kind: Kind
    var deletedAt: Date

    enum Kind: String, Codable {
        case note
        case folder
    }
}

struct DiarySnapshot: Codable, Equatable {
    var notes: [LoveNote]
    var folders: [NoteFolder]
    var insight: DiaryInsight?
    var tombstones: [DiaryTombstone]

    static let empty = DiarySnapshot(notes: [], folders: [], insight: nil, tombstones: [])
}

struct DiaryInsight: Codable, Equatable, Identifiable {
    var id: UUID
    var generatedAt: Date
    var insufficient: Bool
    var stage: String
    var explanation: String
    var wentWell: [String]
    var wentWrong: [String]
    var toImprove: [String]
    var nextActions: [String]
    var noteCount: Int
    var disclaimer: String

    static let standardDisclaimer = "This is a reflective reading of what you wrote, not a clinical judgement or a fixed verdict about your relationship."
}

enum DiaryFilter: Hashable {
    case all
    case pinned
    case insights
    case folder(UUID)
}

enum DiaryDateFilter: String, CaseIterable, Identifiable {
    case any = "Any time"
    case week = "7 days"
    case month = "30 days"
    case year = "This year"

    var id: String { rawValue }
}

struct DiaryNoteExcerpt: Equatable {
    var title: String
    var date: Date
    var body: String
}

struct RomanticSuggestion: Equatable {
    var text: String
    var usedFallback: Bool
    var notice: String?
}

struct DiarySwatch: Identifiable, Equatable {
    var name: String
    var hex: String
    var id: String { hex }
}

enum DiaryPalette {
    static let folderSwatches: [DiarySwatch] = [
        DiarySwatch(name: "Purple", hex: "9B5CFF"),
        DiarySwatch(name: "Neon green", hex: "3DFF6E"),
        DiarySwatch(name: "Pink", hex: "FF4FA3"),
        DiarySwatch(name: "Sky", hex: "38BDF8"),
        DiarySwatch(name: "Amber", hex: "F5B942"),
        DiarySwatch(name: "Rose", hex: "FB7185")
    ]
}
