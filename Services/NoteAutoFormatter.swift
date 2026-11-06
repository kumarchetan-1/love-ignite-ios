import UIKit

struct StyledNoteLine {
    var kind: NoteTextCleanup.LineKind
    var text: String
    var number: Int?
    var font: UIFont
    var color: UIColor
    var underline: Bool
    var headingHint: Bool
}

enum NoteAutoFormatter {
    static func format(_ source: NSAttributedString) -> NSAttributedString {
        guard source.length > 0 else { return source }
        let result = NSMutableAttributedString()
        source.enumerateAttribute(.attachment, in: NSRange(location: 0, length: source.length)) { value, range, _ in
            let chunk = source.attributedSubstring(from: range)
            if value != nil {
                if result.length > 0, !result.string.hasSuffix("\n") {
                    result.append(NSAttributedString(string: "\n", attributes: RichTextArchive.bodyAttributes))
                }
                result.append(chunk)
            } else {
                let cleaned = formatText(chunk)
                if cleaned.length > 0 {
                    result.append(cleaned)
                }
            }
        }
        return result.length > 0 ? result : source
    }

    private static func formatText(_ source: NSAttributedString) -> NSAttributedString {
        let pieces = paragraphs(from: source)
        let classified: [StyledNoteLine] = pieces.map { piece in
            let line = NoteTextCleanup.classify(piece.text)
            let kind: NoteTextCleanup.LineKind = {
                if line.kind == .body && piece.headingHint {
                    return .heading
                }
                return line.kind
            }()
            return StyledNoteLine(
                kind: kind,
                text: line.text,
                number: nil,
                font: piece.font,
                color: piece.color,
                underline: piece.underline,
                headingHint: piece.headingHint || kind == .heading
            )
        }
        let collapsed = collapse(classified)
        let numbered = renumber(collapsed)
        return render(numbered)
    }

    private struct ParagraphPiece {
        var text: String
        var font: UIFont
        var color: UIColor
        var underline: Bool
        var headingHint: Bool
    }

    private static func paragraphs(from source: NSAttributedString) -> [ParagraphPiece] {
        let raw = source.string as NSString
        guard raw.length > 0 else { return [] }
        var pieces: [ParagraphPiece] = []
        var location = 0
        while location < raw.length {
            let paragraph = raw.paragraphRange(for: NSRange(location: location, length: 0))
            if paragraph.length == 0 {
                break
            }
            var text = raw.substring(with: paragraph)
            if text.hasSuffix("\n") {
                text.removeLast()
            }
            let probe = min(paragraph.location, max(source.length - 1, 0))
            let font = source.attribute(.font, at: probe, effectiveRange: nil) as? UIFont
                ?? UIFont.preferredFont(forTextStyle: .body)
            let color = source.attribute(.foregroundColor, at: probe, effectiveRange: nil) as? UIColor ?? .label
            let underline = (source.attribute(.underlineStyle, at: probe, effectiveRange: nil) as? Int ?? 0) != 0
            pieces.append(ParagraphPiece(
                text: text,
                font: font,
                color: color,
                underline: underline,
                headingHint: font.pointSize >= 21
            ))
            location = paragraph.location + paragraph.length
        }
        return pieces
    }

    private static func collapse(_ lines: [StyledNoteLine]) -> [StyledNoteLine] {
        var output: [StyledNoteLine] = []
        var blankRun = 0
        for line in lines {
            if line.kind == .blank || line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && line.kind != .heading {
                if line.kind == .bullet || line.kind == .numbered {
                    continue
                }
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

    private static func renumber(_ lines: [StyledNoteLine]) -> [StyledNoteLine] {
        var output: [StyledNoteLine] = []
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

    private static func render(_ lines: [StyledNoteLine]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (index, line) in lines.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n"))
            }
            let visible: String
            let font: UIFont
            switch line.kind {
            case .blank:
                visible = ""
                font = line.font
            case .bullet:
                visible = "• \(line.text)"
                font = line.font.withSize(min(line.font.pointSize, 17))
            case .numbered:
                visible = "\(line.number ?? 1). \(line.text)"
                font = line.font.withSize(min(line.font.pointSize, 17))
            case .heading:
                visible = line.text
                font = headingFont(basedOn: line.font)
            case .body:
                visible = line.text
                font = line.font
            }
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: line.color
            ]
            if line.underline {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            let style = NSMutableParagraphStyle()
            style.paragraphSpacing = line.kind == .heading ? 8 : 4
            if line.kind == .bullet || line.kind == .numbered {
                style.headIndent = 18
                style.firstLineHeadIndent = 0
            }
            attributes[.paragraphStyle] = style
            result.append(NSAttributedString(string: visible, attributes: attributes))
        }
        return result
    }

    private static func headingFont(basedOn font: UIFont) -> UIFont {
        var traits = font.fontDescriptor.symbolicTraits
        traits.insert(.traitBold)
        if let descriptor = UIFont.systemFont(ofSize: 22, weight: .bold).fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: 22)
        }
        return UIFont.systemFont(ofSize: 22, weight: .bold)
    }
}
