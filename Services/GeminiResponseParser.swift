import Foundation

enum DiaryAIError: Error {
    case unavailable
    case emptyResponse
    case unreadable
}

struct GeminiDiaryAnalysis: Decodable {
    var insufficient: Bool?
    var stage: String?
    var explanation: String?
    var wentWell: [String]?
    var wentWrong: [String]?
    var toImprove: [String]?
    var nextActions: [String]?
}

enum GeminiResponseParser {
    static func jsonObjectData(from text: String) -> Data? {
        let stripped = stripFence(text)
        guard let range = objectRange(in: stripped) else { return nil }
        return String(stripped[range]).data(using: .utf8)
    }

    static func analysis(from text: String) -> GeminiDiaryAnalysis? {
        guard let data = jsonObjectData(from: text) else { return nil }
        return try? JSONDecoder().decode(GeminiDiaryAnalysis.self, from: data)
    }

    static func cleanedNote(_ text: String) -> String {
        var lines = stripFence(text).components(separatedBy: "\n")
        if let first = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines),
           first.hasSuffix(":"),
           first.count < 80,
           lines.count > 1 {
            lines.removeFirst()
        }
        var value = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("\""), value.hasSuffix("\""), value.count > 1 {
            value.removeFirst()
            value.removeLast()
        }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripFence(_ text: String) -> String {
        var lines = text.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        if lines.first?.trimmingCharacters(in: .whitespaces).hasPrefix("```") == true {
            lines.removeFirst()
        }
        if lines.last?.trimmingCharacters(in: .whitespaces).hasPrefix("```") == true {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    /// First balanced `{...}` object, ignoring braces that sit inside strings.
    private static func objectRange(in text: String) -> Range<String.Index>? {
        var start: String.Index?
        var depth = 0
        var inString = false
        var escaped = false
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == "{" {
                if depth == 0 {
                    start = index
                }
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0, let start {
                    return start..<text.index(after: index)
                }
            }
            index = text.index(after: index)
        }
        return nil
    }
}
