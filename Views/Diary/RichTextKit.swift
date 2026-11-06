import SwiftUI
import Combine
import UIKit

enum NoteTextColor: String, CaseIterable, Identifiable {
    case automatic
    case purple
    case green
    case pink
    case sky
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "Default"
        case .purple:
            return "Purple"
        case .green:
            return "Green"
        case .pink:
            return "Pink"
        case .sky:
            return "Sky"
        case .amber:
            return "Amber"
        }
    }

    var uiColor: UIColor {
        switch self {
        case .automatic:
            return .label
        case .purple:
            return HexColor.uiColor("9B5CFF")
        case .green:
            return HexColor.uiColor("1FA84A")
        case .pink:
            return HexColor.uiColor("FF4FA3")
        case .sky:
            return HexColor.uiColor("38BDF8")
        case .amber:
            return HexColor.uiColor("C98412")
        }
    }

    var swatch: Color {
        switch self {
        case .automatic:
            return .primary
        case .purple:
            return HexColor.color("9B5CFF")
        case .green:
            return HexColor.color("1FA84A")
        case .pink:
            return HexColor.color("FF4FA3")
        case .sky:
            return HexColor.color("38BDF8")
        case .amber:
            return HexColor.color("C98412")
        }
    }
}

extension UIFont {
    func withTrait(_ trait: UIFontDescriptor.SymbolicTraits, enabled: Bool) -> UIFont {
        var traits = fontDescriptor.symbolicTraits
        if enabled {
            traits.insert(trait)
        } else {
            traits.remove(trait)
        }
        if let descriptor = fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: pointSize)
        }
        let weight: UIFont.Weight = traits.contains(.traitBold) ? .semibold : .regular
        var fallback = UIFont.systemFont(ofSize: pointSize, weight: weight)
        if traits.contains(.traitItalic), let italic = fallback.fontDescriptor.withSymbolicTraits(.traitItalic) {
            fallback = UIFont(descriptor: italic, size: pointSize)
        }
        return fallback
    }
}

enum RichTextEditing {
    static func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits, in textView: UITextView) {
        let range = textView.selectedRange
        if range.length == 0 {
            var attributes = textView.typingAttributes
            let font = (attributes[.font] as? UIFont) ?? UIFont.preferredFont(forTextStyle: .body)
            attributes[.font] = font.withTrait(trait, enabled: !font.fontDescriptor.symbolicTraits.contains(trait))
            textView.typingAttributes = attributes
            return
        }
        textView.textStorage.beginEditing()
        textView.textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? UIFont) ?? UIFont.preferredFont(forTextStyle: .body)
            textView.textStorage.addAttribute(
                .font,
                value: font.withTrait(trait, enabled: !font.fontDescriptor.symbolicTraits.contains(trait)),
                range: subrange
            )
        }
        textView.textStorage.endEditing()
    }

    static func toggleUnderline(in textView: UITextView) {
        let range = textView.selectedRange
        if range.length == 0 {
            var attributes = textView.typingAttributes
            let current = attributes[.underlineStyle] as? Int ?? 0
            attributes[.underlineStyle] = current == 0 ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes = attributes
            return
        }
        var anyPlain = false
        textView.textStorage.enumerateAttribute(.underlineStyle, in: range) { value, _, stop in
            if (value as? Int ?? 0) == 0 {
                anyPlain = true
                stop.pointee = true
            }
        }
        textView.textStorage.addAttribute(
            .underlineStyle,
            value: anyPlain ? NSUnderlineStyle.single.rawValue : 0,
            range: range
        )
    }

    static func applyHeading(in textView: UITextView) {
        let font = UIFont.systemFont(ofSize: 22, weight: .bold)
        let storage = textView.textStorage
        let paragraph = (storage.string as NSString).paragraphRange(for: textView.selectedRange)
        if paragraph.length == 0 {
            var attributes = textView.typingAttributes
            attributes[.font] = font
            textView.typingAttributes = attributes
            return
        }
        storage.addAttribute(.font, value: font, range: paragraph)
    }

    static func applyBody(in textView: UITextView) {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let storage = textView.textStorage
        let paragraph = (storage.string as NSString).paragraphRange(for: textView.selectedRange)
        if paragraph.length == 0 {
            var attributes = textView.typingAttributes
            attributes[.font] = font
            attributes[.underlineStyle] = 0
            textView.typingAttributes = attributes
            return
        }
        storage.addAttribute(.font, value: font, range: paragraph)
        storage.removeAttribute(.underlineStyle, range: paragraph)
    }

    static func applyColor(_ color: UIColor, in textView: UITextView) {
        let range = textView.selectedRange
        if range.length == 0 {
            var attributes = textView.typingAttributes
            attributes[.foregroundColor] = color
            textView.typingAttributes = attributes
            return
        }
        textView.textStorage.addAttribute(.foregroundColor, value: color, range: range)
    }

    static func toggleList(numbered: Bool, in textView: UITextView) {
        let storage = textView.textStorage
        let ns = storage.string as NSString
        if ns.length == 0 {
            insertPlain(numbered ? "1. " : "• ", in: textView)
            return
        }
        let block = ns.paragraphRange(for: textView.selectedRange)
        let raw = ns.substring(with: block)
        let trailingNewline = raw.hasSuffix("\n")
        var lines = raw.components(separatedBy: "\n")
        if trailingNewline, lines.last?.isEmpty == true {
            lines.removeLast()
        }
        let pattern = numbered ? "^\\s*\\d+[.)]\\s+" : "^\\s*•\\s+"
        let contentLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let already = !contentLines.isEmpty && contentLines.allSatisfy { line in
            line.range(of: pattern, options: .regularExpression) != nil
        }
        let preservedColor = storage.attribute(.foregroundColor, at: min(block.location, max(ns.length - 1, 0)), effectiveRange: nil) as? UIColor ?? .label
        var rebuilt: [String] = []
        var number = 1
        for line in lines {
            let stripped = stripMarker(line)
            if stripped.isEmpty {
                rebuilt.append("")
                continue
            }
            if already {
                rebuilt.append(stripped)
            } else if numbered {
                rebuilt.append("\(number). \(stripped)")
                number += 1
            } else {
                rebuilt.append("• \(stripped)")
            }
        }
        var replacement = rebuilt.joined(separator: "\n")
        if trailingNewline {
            replacement += "\n"
        }
        storage.replaceCharacters(in: block, with: replacement)
        let newRange = NSRange(location: block.location, length: (replacement as NSString).length)
        if newRange.length > 0 {
            storage.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: newRange)
            storage.addAttribute(.foregroundColor, value: preservedColor, range: newRange)
            let style = NSMutableParagraphStyle()
            style.headIndent = already ? 0 : 18
            style.paragraphSpacing = 4
            storage.addAttribute(.paragraphStyle, value: style, range: newRange)
        }
        textView.selectedRange = NSRange(location: min(block.location + newRange.length, storage.length), length: 0)
    }

    static func insertImage(_ image: UIImage, in textView: UITextView) {
        let resized = DiaryImageCoding.scaled(image, maxDimension: 1400)
        let attachment = NSTextAttachment()
        attachment.image = resized
        let width = max(min(textView.bounds.width - 28, 320), 180)
        let ratio = resized.size.height / max(resized.size.width, 1)
        attachment.bounds = CGRect(x: 0, y: 0, width: width, height: max(width * ratio, 40))
        let insertion = NSMutableAttributedString(attachment: attachment)
        insertion.append(NSAttributedString(string: "\n", attributes: RichTextArchive.bodyAttributes))
        let location = min(textView.selectedRange.location, textView.textStorage.length)
        textView.textStorage.insert(insertion, at: location)
        textView.selectedRange = NSRange(location: min(location + insertion.length, textView.textStorage.length), length: 0)
    }

    static func insertPlain(_ text: String, in textView: UITextView) {
        let attributes = textView.typingAttributes.isEmpty ? RichTextArchive.bodyAttributes : textView.typingAttributes
        let piece = NSAttributedString(string: text, attributes: attributes)
        let location = min(textView.selectedRange.location, textView.textStorage.length)
        textView.textStorage.insert(piece, at: location)
        textView.selectedRange = NSRange(location: min(location + piece.length, textView.textStorage.length), length: 0)
    }

    static func removeOccurrence(of string: String, in textView: UITextView) {
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let range = (mutable.string as NSString).range(of: string, options: .caseInsensitive)
        guard range.location != NSNotFound else { return }
        mutable.replaceCharacters(in: range, with: "")
        textView.attributedText = mutable
    }

    private static func stripMarker(_ line: String) -> String {
        guard let range = line.range(of: "^\\s*(?:•|[-*]|\\d+[.)])\\s+", options: .regularExpression) else {
            return line.trimmingCharacters(in: .whitespaces)
        }
        return String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
    }
}

final class RichTextController: NSObject, ObservableObject, UITextViewDelegate {
    @Published private(set) var isEmpty = true
    @Published private(set) var editCount = 0

    private weak var textView: UITextView?
    private var snapshot: NSAttributedString?
    private var suppressDelegate = false

    func attach(_ textView: UITextView) {
        guard self.textView !== textView else { return }
        self.textView = textView
        textView.delegate = self
        guard let snapshot else { return }
        suppressDelegate = true
        textView.attributedText = snapshot
        suppressDelegate = false
        updateEmpty(snapshot)
    }

    func currentText() -> NSAttributedString {
        if let textView, let attributed = textView.attributedText {
            return NSAttributedString(attributedString: attributed)
        }
        return snapshot ?? NSAttributedString(string: "", attributes: RichTextArchive.bodyAttributes)
    }

    func replaceAll(_ attributed: NSAttributedString) {
        let value = attributed.length == 0
            ? NSAttributedString(string: "", attributes: RichTextArchive.bodyAttributes)
            : attributed
        snapshot = value
        updateEmpty(value)
        guard let textView else {
            editCount += 1
            return
        }
        suppressDelegate = true
        textView.attributedText = value
        suppressDelegate = false
        editCount += 1
    }

    func bold() { edit { RichTextEditing.toggleTrait(.traitBold, in: $0) } }
    func italic() { edit { RichTextEditing.toggleTrait(.traitItalic, in: $0) } }
    func underline() { edit { RichTextEditing.toggleUnderline(in: $0) } }
    func heading() { edit { RichTextEditing.applyHeading(in: $0) } }
    func bodyStyle() { edit { RichTextEditing.applyBody(in: $0) } }
    func bulletList() { edit { RichTextEditing.toggleList(numbered: false, in: $0) } }
    func numberedList() { edit { RichTextEditing.toggleList(numbered: true, in: $0) } }
    func color(_ color: UIColor) { edit { RichTextEditing.applyColor(color, in: $0) } }
    func insertImage(_ image: UIImage) { edit { RichTextEditing.insertImage(image, in: $0) } }
    func insertPlain(_ text: String) { edit { RichTextEditing.insertPlain(text, in: $0) } }
    func removeOccurrence(of string: String) { edit { RichTextEditing.removeOccurrence(of: string, in: $0) } }

    func textViewDidChange(_ textView: UITextView) {
        guard !suppressDelegate else { return }
        let value = textView.attributedText ?? NSAttributedString(string: "")
        snapshot = NSAttributedString(attributedString: value)
        updateEmpty(value)
        editCount += 1
    }

    private func edit(_ change: (UITextView) -> Void) {
        guard let textView else { return }
        change(textView)
        textViewDidChange(textView)
    }

    private func updateEmpty(_ value: NSAttributedString) {
        let empty = RichTextArchive.plainText(from: value).isEmpty && !RichTextArchive.containsAttachment(value)
        if empty != isEmpty {
            isEmpty = empty
        }
    }
}

struct RichTextEditor: UIViewRepresentable {
    @ObservedObject var controller: RichTextController

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.tintColor = UIColor(red: 0.62, green: 0.36, blue: 1, alpha: 1)
        textView.alwaysBounceVertical = true
        textView.allowsEditingTextAttributes = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.typingAttributes = RichTextArchive.bodyAttributes
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.adjustsFontForContentSizeCategory = true
        textView.keyboardDismissMode = .interactive
        textView.autocorrectionType = .yes
        controller.attach(textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        controller.attach(uiView)
    }
}
