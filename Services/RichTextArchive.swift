import UIKit

enum RichTextArchive {
    static var bodyAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ]
    }

    static func plainText(from source: NSAttributedString) -> String {
        stripAttachments(source).string
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func rtfData(from source: NSAttributedString) -> Data? {
        let stripped = stripAttachments(source)
        guard stripped.length > 0 else { return nil }
        let range = NSRange(location: 0, length: stripped.length)
        return try? stripped.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    static func rtfdData(from source: NSAttributedString) -> Data? {
        guard source.length > 0 else { return nil }
        let range = NSRange(location: 0, length: source.length)
        return try? source.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
    }

    static func attributedString(rtfd data: Data) -> NSAttributedString? {
        try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtfd],
            documentAttributes: nil
        )
    }

    static func attributedString(rtf data: Data) -> NSAttributedString? {
        try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }

    static func plain(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: bodyAttributes)
    }

    static func containsAttachment(_ source: NSAttributedString) -> Bool {
        var found = false
        source.enumerateAttribute(.attachment, in: NSRange(location: 0, length: source.length)) { value, _, stop in
            if value != nil {
                found = true
                stop.pointee = true
            }
        }
        return found
    }

    static func stripAttachments(_ source: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: source)
        var ranges: [NSRange] = []
        mutable.enumerateAttribute(.attachment, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
            if value != nil {
                ranges.append(range)
            }
        }
        for range in ranges.reversed() {
            mutable.replaceCharacters(in: range, with: "\n")
        }
        return mutable
    }
}

enum DiaryImageCoding {
    static func jpegData(from image: UIImage) -> Data? {
        let resized = scaled(image, maxDimension: 1600)
        return resized.jpegData(compressionQuality: 0.82)
    }

    static func image(from attachment: NSTextAttachment) -> UIImage? {
        if let image = attachment.image {
            return image
        }
        if let data = attachment.fileWrapper?.regularFileContents, let image = UIImage(data: data) {
            return image
        }
        if let data = attachment.contents, let image = UIImage(data: data) {
            return image
        }
        return nil
    }

    static func scaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
