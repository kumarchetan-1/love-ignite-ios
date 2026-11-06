import Foundation

enum VideoLinkParser {
    static func links(in text: String) -> [NoteVideoLink] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var found: [NoteVideoLink] = []
        detector.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match, let url = match.url, let link = make(from: url, forced: false) else { return }
            if found.contains(where: { $0.urlString.caseInsensitiveCompare(link.urlString) == .orderedSame }) {
                return
            }
            found.append(link)
        }
        return found
    }

    static func normalize(_ raw: String) -> URL? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.contains("://") {
            text = "https://" + text
        }
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host,
              !host.isEmpty else {
            return nil
        }
        return url
    }

    /// `forced` keeps a link the user pasted on purpose, even if the host is unfamiliar.
    static func make(from url: URL, forced: Bool) -> NoteVideoLink? {
        guard let platform = classify(url) ?? (forced ? .other : nil) else { return nil }
        let title: String
        switch platform {
        case .youtube:
            title = "YouTube"
        case .instagram:
            title = "Instagram Reel"
        case .other:
            title = url.host?.replacingOccurrences(of: "www.", with: "") ?? "Video"
        }
        return NoteVideoLink(id: UUID(), urlString: url.absoluteString, platform: platform, title: title)
    }

    static func thumbnailURL(for link: NoteVideoLink) -> URL? {
        guard link.platform == .youtube, let url = link.url, let identifier = youtubeID(from: url) else {
            return nil
        }
        return URL(string: "https://img.youtube.com/vi/\(identifier)/hqdefault.jpg")
    }

    static func classify(_ url: URL) -> VideoPlatform? {
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        if host.contains("youtube.com") || host.contains("youtu.be") || host.contains("youtube-nocookie.com") {
            return .youtube
        }
        if host.contains("instagram.com") && (path.contains("/reel/") || path.contains("/reels/") || path.contains("/tv/")) {
            return .instagram
        }
        if host.contains("vimeo.com") || host.contains("tiktok.com") || host.contains("dailymotion.com")
            || host.contains("fb.watch") || path.contains("/video") || path.contains("/watch") {
            return .other
        }
        return nil
    }

    static func youtubeID(from url: URL) -> String? {
        let host = (url.host ?? "").lowercased()
        if host.contains("youtu.be") {
            return cleanID(url.pathComponents.dropFirst().first)
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let value = items.first(where: { $0.name == "v" })?.value {
            return cleanID(value)
        }
        let parts = url.pathComponents
        if let marker = parts.firstIndex(where: { ["shorts", "embed", "live", "v"].contains($0) }),
           marker + 1 < parts.count {
            return cleanID(parts[marker + 1])
        }
        return nil
    }

    private static func cleanID(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6, trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
            return nil
        }
        return trimmed
    }
}
