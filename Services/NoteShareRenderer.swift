import UIKit
import SwiftUI

enum NoteShareRenderer {
    static func plainText(title: String, body: String, links: [NoteVideoLink]) -> String {
        var parts: [String] = []
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            parts.append(trimmedTitle)
        }
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBody.isEmpty {
            parts.append(trimmedBody)
        }
        if !links.isEmpty {
            let lines = links.map { "\($0.title): \($0.urlString)" }
            parts.append(lines.joined(separator: "\n"))
        }
        parts.append("Shared from LDiary")
        return parts.joined(separator: "\n\n")
    }

    static func pdfURL(title: String, body: NSAttributedString, links: [NoteVideoLink]) -> URL? {
        let content = exportBody(title: title, body: body, links: links, color: .black, background: .white)
        let pageWidth: CGFloat = 612
        let margin: CGFloat = 48
        let contentWidth = pageWidth - margin * 2
        let bounds = content.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = max(792, ceil(bounds.height) + margin * 2 + 24)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: height))
        let data = renderer.pdfData { context in
            context.beginPage()
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: height))
            content.draw(in: CGRect(x: margin, y: margin, width: contentWidth, height: bounds.height + 8))
        }
        return writeTemp(data, name: safeFileName(title, ext: "pdf"))
    }

    static func imageURL(title: String, body: NSAttributedString, links: [NoteVideoLink]) -> URL? {
        let content = exportBody(title: title, body: body, links: links, color: .label, background: .clear)
        let width: CGFloat = 360
        let margin: CGFloat = 24
        let contentWidth = width - margin * 2
        let bounds = content.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = min(4800, max(420, ceil(bounds.height) + margin * 2 + 36))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let colors = [UIColor(red: 0.16, green: 0.08, blue: 0.28, alpha: 1).cgColor, UIColor(red: 0.08, green: 0.16, blue: 0.12, alpha: 1).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: width, y: height), options: [])
            } else {
                UIColor.black.setFill()
                context.fill(rect)
            }
            let card = rect.insetBy(dx: 12, dy: 12)
            let path = UIBezierPath(roundedRect: card, cornerRadius: 22)
            UIColor(white: 1, alpha: 0.08).setFill()
            path.fill()
            content.draw(in: CGRect(x: margin, y: margin, width: contentWidth, height: height - margin * 2))
        }
        guard let data = image.pngData() else { return nil }
        return writeTemp(data, name: safeFileName(title, ext: "png"))
    }

    private static func exportBody(title: String, body: NSAttributedString, links: [NoteVideoLink], color: UIColor, background: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let heading: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: color
        ]
        let caption: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: color.withAlphaComponent(0.7)
        ]
        result.append(NSAttributedString(string: "LDiary\n", attributes: caption))
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        result.append(NSAttributedString(string: (trimmedTitle.isEmpty ? "Untitled note" : trimmedTitle) + "\n\n", attributes: heading))
        if body.length > 0 {
            result.append(body)
            result.append(NSAttributedString(string: "\n\n", attributes: [.foregroundColor: color]))
        }
        if !links.isEmpty {
            let linkFont: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: color
            ]
            for link in links {
                result.append(NSAttributedString(string: "\(link.title)\n\(link.urlString)\n\n", attributes: linkFont))
            }
        }
        result.append(NSAttributedString(string: "Shared from LDiary", attributes: caption))
        _ = background
        return result
    }

    private static func writeTemp(_ data: Data, name: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func safeFileName(_ title: String, ext: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "LDiary-note" : trimmed
        let cleaned = base.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "-", options: .regularExpression)
        let clipped = String(cleaned.prefix(40)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "\(clipped.isEmpty ? "LDiary-note" : clipped).\(ext)"
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let items: [Any]

    func makeUIViewController(context: Context) -> ShareHostController {
        let controller = ShareHostController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ controller: ShareHostController, context: Context) {
        controller.items = items
        controller.isPresented = isPresented
        controller.onFinish = { isPresented = false }
        DispatchQueue.main.async {
            controller.sync()
        }
    }
}

final class ShareHostController: UIViewController {
    var items: [Any] = []
    var isPresented = false
    var onFinish: (() -> Void)?
    private var didPresent = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sync()
    }

    func sync() {
        if !isPresented {
            didPresent = false
            return
        }
        guard !didPresent, presentedViewController == nil, view.window != nil, !items.isEmpty else { return }
        didPresent = true
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.didPresent = false
            self?.onFinish?()
        }
        present(activity, animated: true)
    }
}
