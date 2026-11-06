import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct NoteEditorView: View {
    let noteID: UUID

    @EnvironmentObject private var diary: DiaryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var richText = RichTextController()

    @State private var title = ""
    @State private var isPinned = false
    @State private var videoLinks: [NoteVideoLink] = []
    @State private var wasPersisted = false
    @State private var didLoad = false
    @State private var missingPhotos = 0
    @State private var photoItem: PhotosPickerItem?
    @State private var showLinkPrompt = false
    @State private var linkDraft = ""
    @State private var linkError: String?
    @State private var showRomantic = false
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("Title", text: $title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(ThemePalette.primaryText(for: scheme))
                    formattingBar
                    editor
                    actionRow
                    if !videoLinks.isEmpty {
                        videoSection
                    }
                    if missingPhotos > 0 {
                        Text("\(missingPhotos) photo\(missingPhotos == 1 ? "" : "s") from this note stayed on the device that added them. iCloud key-value storage can't carry images.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 140)
            }
        }
        .background(Color.clear)
        .background {
            ActivityShareSheet(isPresented: $showShare, items: shareItems)
        }
        .onAppear(perform: loadIfNeeded)
        .onDisappear {
            persistOrDiscard()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                persistOrDiscard()
            }
        }
        .onChange(of: richText.editCount) { _ in
            refreshLinkPreviews()
        }
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                await insertPickedImage(item)
            }
        }
        .alert("Video link", isPresented: $showLinkPrompt) {
            TextField("https://", text: $linkDraft)
            Button("Add") { addLink() }
            Button("Cancel", role: .cancel) { linkDraft = "" }
        } message: {
            Text("Paste an Instagram Reel, YouTube, or other video link. The address is saved with the note and opens when you tap it.")
        }
        .alert("Link", isPresented: Binding(get: { linkError != nil }, set: { if !$0 { linkError = nil } })) {
            Button("OK", role: .cancel) { linkError = nil }
        } message: {
            Text(linkError ?? "")
        }
        .sheet(isPresented: $showRomantic) {
            RomanticRewriteSheet(sourceText: RichTextArchive.plainText(from: richText.currentText())) { suggestion in
                richText.replaceAll(RichTextArchive.plain(suggestion.text))
                refreshLinkPreviews()
            }
            .environmentObject(diary)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Back")
            VStack(alignment: .leading, spacing: 2) {
                Text("LDiary")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(ThemePalette.neonGreen)
                Text("Your love, written down")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
            Spacer()
            Button {
                isPinned.toggle()
                Haptics.selection()
            } label: {
                Image(systemName: isPinned ? "star.fill" : "star")
                    .foregroundColor(isPinned ? ThemePalette.neonGreen : ThemePalette.secondaryText(for: scheme))
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(isPinned ? "Unpin note" : "Pin note")
            Menu {
                Button("Share text") { share(.text) }
                Button("Share PDF") { share(.pdf) }
                Button("Share image") { share(.image) }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Share note")
        }
        .foregroundColor(ThemePalette.primaryText(for: scheme))
        .padding(.horizontal, 12)
        .padding(.top, 56)
        .padding(.bottom, 8)
    }

    private var formattingBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FormatIconButton(name: "bold", label: "Bold") { richText.bold() }
                FormatIconButton(name: "italic", label: "Italic") { richText.italic() }
                FormatIconButton(name: "underline", label: "Underline") { richText.underline() }
                FormatIconButton(name: "textformat.size", label: "Heading") { richText.heading() }
                FormatIconButton(name: "textformat", label: "Body") { richText.bodyStyle() }
                FormatIconButton(name: "list.bullet", label: "Bulleted list") { richText.bulletList() }
                FormatIconButton(name: "list.number", label: "Numbered list") { richText.numberedList() }
                Menu {
                    ForEach(NoteTextColor.allCases) { color in
                        Button {
                            richText.color(color.uiColor)
                        } label: {
                            Label(color.title, systemImage: "circle.fill")
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette.fill")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Text colour")
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo")
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Attach photo")
                FormatIconButton(name: "link", label: "Add video link") { showLinkPrompt = true }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(ThemePalette.primaryText(for: scheme))
            .padding(.vertical, 4)
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RichTextEditor(controller: richText)
                .frame(minHeight: 280)
            if richText.isEmpty {
                Text("Write what you want to remember…")
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    .padding(.top, 20)
                    .padding(.leading, 14)
                    .allowsHitTesting(false)
            }
        }
        .neonCard(cornerRadius: 20)
    }

    private var actionRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                richText.replaceAll(NoteAutoFormatter.format(richText.currentText()))
                Haptics.light()
            } label: {
                Label("Auto-format", systemImage: "text.alignleft")
            }
            Button {
                showRomantic = true
            } label: {
                Label("Make it romantic", systemImage: "heart.text.square")
            }
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .buttonStyle(.bordered)
        .tint(ThemePalette.neonPurple)
    }

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Videos")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
            ForEach(videoLinks) { link in
                VideoLinkRow(link: link) {
                    videoLinks.removeAll { $0.id == link.id }
                    richText.removeOccurrence(of: link.urlString)
                }
            }
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        guard let note = diary.note(id: noteID) else { return }
        title = note.title
        isPinned = note.isPinned
        videoLinks = note.videoLinks
        wasPersisted = diary.isPersisted(noteID)
        let document = diary.document(for: note)
        missingPhotos = diary.missingImageCount(for: note, attributed: document)
        richText.replaceAll(document)
    }

    private func persistOrDiscard() {
        let attributed = richText.currentText()
        let plain = RichTextArchive.plainText(from: attributed)
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasMedia = RichTextArchive.containsAttachment(attributed) || !videoLinks.isEmpty
        if !wasPersisted && plain.isEmpty && !hasTitle && !hasMedia {
            diary.discardUnsaved(noteID: noteID)
            return
        }
        diary.save(
            noteID: noteID,
            title: title,
            attributed: attributed,
            videoLinks: videoLinks,
            isPinned: isPinned
        )
        wasPersisted = true
    }

    private func refreshLinkPreviews() {
        let plain = RichTextArchive.plainText(from: richText.currentText())
        let detected = VideoLinkParser.links(in: plain)
        var next = videoLinks.filter { link in
            plain.range(of: link.urlString, options: .caseInsensitive) != nil
        }
        for link in detected where !next.contains(where: { $0.urlString.caseInsensitiveCompare(link.urlString) == .orderedSame }) {
            next.append(link)
        }
        if next != videoLinks {
            videoLinks = next
        }
    }

    private func addLink() {
        let raw = linkDraft
        linkDraft = ""
        guard let url = VideoLinkParser.normalize(raw), let link = VideoLinkParser.make(from: url, forced: true) else {
            linkError = "That doesn't look like a web link yet."
            return
        }
        if videoLinks.contains(where: { $0.urlString.caseInsensitiveCompare(link.urlString) == .orderedSame }) {
            return
        }
        videoLinks.append(link)
        let plain = RichTextArchive.plainText(from: richText.currentText())
        if plain.range(of: link.urlString, options: .caseInsensitive) == nil {
            let prefix = plain.isEmpty ? "" : "\n"
            richText.insertPlain(prefix + link.urlString)
        }
        Haptics.selection()
    }

    private func insertPickedImage(_ item: PhotosPickerItem) async {
        defer { photoItem = nil }
        guard let picked = try? await item.loadTransferable(type: PickedImage.self),
              let image = UIImage(data: picked.data) else {
            linkError = "That photo couldn't be attached."
            return
        }
        richText.insertImage(image)
        Haptics.light()
    }

    private enum ShareKind {
        case text
        case pdf
        case image
    }

    private func share(_ kind: ShareKind) {
        let plain = NoteShareRenderer.plainText(
            title: title,
            body: RichTextArchive.plainText(from: richText.currentText()),
            links: videoLinks
        )
        let body = richText.currentText()
        switch kind {
        case .text:
            shareItems = [plain]
        case .pdf:
            if let url = NoteShareRenderer.pdfURL(title: title, body: body, links: videoLinks) {
                shareItems = [url]
            } else {
                shareItems = [plain]
            }
        case .image:
            if let url = NoteShareRenderer.imageURL(title: title, body: body, links: videoLinks) {
                shareItems = [url]
            } else {
                shareItems = [plain]
            }
        }
        showShare = true
    }
}

private struct PickedImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickedImage(data: data)
        }
    }
}

private struct FormatIconButton: View {
    let name: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: name)
                .frame(width: 36, height: 36)
        }
        .accessibilityLabel(label)
    }
}

struct VideoLinkRow: View {
    let link: NoteVideoLink
    var onRemove: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 8) {
            openButton
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
            .accessibilityLabel("Remove link")
        }
        .padding(12)
        .neonCard(cornerRadius: 16)
        .accessibilityElement(children: .contain)
    }

    private var openButton: some View {
        Button {
            guard let url = link.url else { return }
            openURL(url)
        } label: {
            HStack(spacing: 12) {
                thumbnail
                VStack(alignment: .leading, spacing: 3) {
                    Text(link.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(ThemePalette.primaryText(for: scheme))
                    Text(link.platform.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ThemePalette.neonGreen)
                    Text(link.url?.host ?? link.urlString)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ThemePalette.secondaryText(for: scheme))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ThemePalette.neonPurple)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(link.title), \(link.platform.label)")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnail = VideoLinkParser.thumbnailURL(for: link) {
            AsyncImage(url: thumbnail) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty, .failure:
                    iconTile
                @unknown default:
                    iconTile
                }
            }
            .frame(width: 64, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            iconTile
        }
    }

    private var iconTile: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(ThemePalette.neonPurple.opacity(0.18))
            .frame(width: 64, height: 48)
            .overlay(
                Image(systemName: link.platform.systemImage)
                    .foregroundColor(ThemePalette.neonPurple)
            )
    }
}
