import Foundation

/// Local spacing, capitalisation, and list cleanup. No network.
enum NoteTextCleanup {
    enum LineKind: Equatable {
        case blank
        case bullet
        case numbered
        case heading
        case body
    }

    struct Line: Equatable {
        var kind: LineKind
        var text: String
        var number: Int?
    }

    static func cleanup(_ raw: String) -> String {
        render(renumber(collapseBlanks(split(raw).map(classify))))
    }

    static func split(_ raw: String) -> [String] {
        raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    static func classify(_ rawLine: String) -> Line {
        let trimmedEnd = rawLine.replacingOccurrences(of: "[ \\t]+$", with: "", options: .regularExpression)
        let trimmed = trimmedEnd.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return Line(kind: .blank, text: "")
        }
        if let heading = firstMatch(in: trimmed, pattern: "^#{1,3}\\s+(.+)$") {
            return Line(kind: .heading, text: polish(heading))
        }
        if let body = firstMatch(in: trimmed, pattern: "^[-*•]\\s+(.+)$") {
            return Line(kind: .bullet, text: polish(body))
        }
        if let body = firstMatch(in: trimmed, pattern: "^\\d+[.)]\\s+(.+)$") {
            return Line(kind: .numbered, text: polish(body))
        }
        return Line(kind: .body, text: polish(trimmed))
    }

    static func collapseBlanks(_ lines: [Line]) -> [Line] {
        var output: [Line] = []
        var blankRun = 0
        for line in lines {
            if line.kind == .blank {
                blankRun += 1
                if blankRun <= 1, !output.isEmpty {
                    output.append(line)
                }
            } else {
                blankRun = 0
                output.append(line)
            }
        }
        while output.last?.kind == .blank {
            output.removeLast()
        }
        return output
    }

    static func renumber(_ lines: [Line]) -> [Line] {
        var output: [Line] = []
        var number = 1
        var inRun = false
        for line in lines {
            var copy = line
            switch line.kind {
            case .numbered:
                if !inRun {
                    number = 1
                    inRun = true
                }
                copy.number = number
                number += 1
            case .blank:
                inRun = false
            case .bullet, .heading, .body:
                inRun = false
            }
            output.append(copy)
        }
        return output
    }

    static func render(_ lines: [Line]) -> String {
        lines.map { line in
            switch line.kind {
            case .blank:
                return ""
            case .bullet:
                return "• \(line.text)"
            case .numbered:
                return "\(line.number ?? 1). \(line.text)"
            case .heading, .body:
                return line.text
            }
        }
        .joined(separator: "\n")
    }

    /// Gentle offline pass used when Gemini is unavailable. It does not add new sentences.
    static func romanticTidy(_ raw: String) -> String {
        let cleaned = cleanup(raw)
        return cleaned.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }

    private static func polish(_ text: String) -> String {
        var value = text.replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
        value = value.replacingOccurrences(of: "\\s+([,.;:!?])", with: "$1", options: .regularExpression)
        value = value.replacingOccurrences(of: "([,;:])(\\p{L})", with: "$1 $2", options: .regularExpression)
        value = value.replacingOccurrences(of: "([.!?])(\\p{L})", with: "$1 $2", options: .regularExpression)
        value = capitalizeSentences(value)
        value = value.replacingOccurrences(of: "\\bi\\b", with: "I", options: .regularExpression)
        return value.trimmingCharacters(in: .whitespaces)
    }

    private static func capitalizeSentences(_ text: String) -> String {
        var result = ""
        var shouldCapitalize = true
        for character in text {
            if shouldCapitalize, character.isLetter {
                result.append(contentsOf: String(character).uppercased())
                shouldCapitalize = false
            } else {
                result.append(character)
                if character.isLetter || character.isNumber {
                    shouldCapitalize = false
                }
            }
            if character == "." || character == "!" || character == "?" {
                shouldCapitalize = true
            }
        }
        return result
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
              let capture = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[capture])
    }
}
