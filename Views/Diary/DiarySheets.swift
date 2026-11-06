import SwiftUI

struct InsightConsentSheet: View {
    @EnvironmentObject private var diary: DiaryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var agreed = false
    @State private var working = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Send your notes for a reflection?")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(ThemePalette.primaryText(for: scheme))
                    Text("Analyse my notes sends the titles and text of the notes in this diary to Google Gemini through Firebase. Photos and videos stay on this device and are not included.")
                        .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    Text("Love Ignite does not upload this diary to an account or our own server. The reply is reflective guidance — one possible reading of what you wrote — not a clinical judgement or a fixed verdict about your relationship.")
                        .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    if diary.analysisWillTruncate {
                        Text("A very long diary is shortened before it is sent. The newest notes are kept first.")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(ThemePalette.neonPurple)
                    }
                    if let blocker = diary.analysisBlocker {
                        Text(blocker)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(ThemePalette.primaryText(for: scheme))
                            .padding(14)
                            .neonCard(cornerRadius: 16)
                    } else {
                        Toggle(isOn: $agreed) {
                            Text("Send the text of my notes to Gemini this time")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .tint(ThemePalette.neonPurple)
                        .disabled(working)
                    }
                    if working || diary.isAnalysing {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Asking Gemini…")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Analyse my notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Don't send") { dismiss() }
                        .disabled(working)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { send() }
                        .disabled(!agreed || working || diary.analysisBlocker != nil)
                }
            }
        }
    }

    private func send() {
        guard agreed, diary.analysisBlocker == nil else { return }
        working = true
        diary.filter = .insights
        Task {
            await diary.analyse()
            working = false
            dismiss()
        }
    }
}

struct RomanticRewriteSheet: View {
    @EnvironmentObject private var diary: DiaryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let sourceText: String
    var onAccept: (RomanticSuggestion) -> Void

    @State private var step: Step = .consent
    @State private var agreed = false

    private enum Step {
        case consent
        case working
        case result(RomanticSuggestion)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch step {
                    case .consent:
                        consent
                    case .working:
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Asking Gemini…")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .padding(.top, 24)
                    case .result(let suggestion):
                        result(suggestion)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Make it romantic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make it romantic sends this note's text to Google Gemini through Firebase so it can suggest a warmer wording. Photos and links are not included. You'll see the suggestion next to your original and can keep your own words.")
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
            Text("Nothing is sent until you turn this on and tap Send this note.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ThemePalette.primaryText(for: scheme))
            Toggle(isOn: $agreed) {
                Text("Send this note's text to Gemini this time")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .tint(ThemePalette.neonPurple)
            Button("Send this note") {
                guard agreed else { return }
                step = .working
                let source = sourceText
                Task {
                    let suggestion = await diary.romanticSuggestion(for: source)
                    step = .result(suggestion)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemePalette.neonPurple)
            .disabled(!agreed || sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Write a few words first.")
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
        }
    }

    private func result(_ suggestion: RomanticSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if suggestion.usedFallback {
                Text("Offline")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ThemePalette.neonGreen.opacity(0.2)))
            } else {
                Text("Gemini suggestion")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ThemePalette.neonPurple.opacity(0.2)))
            }
            if let notice = suggestion.notice {
                Text(notice)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
            comparisonCard(title: "Your note", text: sourceText)
            comparisonCard(title: suggestion.usedFallback ? "Tidied wording" : "Warmer wording", text: suggestion.text)
            Text("Using a suggestion replaces the current formatting in this note.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
            if suggestion.text != sourceText && !suggestion.text.isEmpty {
                Button(suggestion.usedFallback ? "Use the tidy" : "Use this wording") {
                    onAccept(suggestion)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemePalette.neonPurple)
            }
            Button("Keep my note") { dismiss() }
                .buttonStyle(.bordered)
        }
    }

    private func comparisonCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(ThemePalette.neonGreen)
            Text(text.isEmpty ? " " : text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(ThemePalette.primaryText(for: scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .neonCard(cornerRadius: 16)
    }
}

struct FolderDraftSheet: View {
    let heading: String
    @State private var name: String
    @State private var colorHex: String
    var onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    init(heading: String, name: String, colorHex: String, onSave: @escaping (String, String) -> Void) {
        self.heading = heading
        _name = State(initialValue: name)
        _colorHex = State(initialValue: colorHex)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                TextField("Folder name", text: $name)
                    .textFieldStyle(.roundedBorder)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 12)], spacing: 12) {
                    ForEach(DiaryPalette.folderSwatches) { swatch in
                        Button {
                            colorHex = swatch.hex
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(HexColor.color(swatch.hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: colorHex == swatch.hex ? 3 : 0)
                                    )
                                Text(swatch.name)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(swatch.name)
                    }
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle(heading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, colorHex)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AssignFolderSheet: View {
    let noteIDs: Set<UUID>
    @EnvironmentObject private var diary: DiaryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("New folder") { showCreate = true }
                    Button("Remove from folder") {
                        diary.assign(noteIDs: noteIDs, to: nil)
                        dismiss()
                    }
                }
                Section("Folders") {
                    if diary.folders.isEmpty {
                        Text("No folders yet.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(diary.folders) { folder in
                        Button {
                            diary.assign(noteIDs: noteIDs, to: folder.id)
                            dismiss()
                        } label: {
                            HStack {
                                Circle().fill(HexColor.color(folder.colorHex)).frame(width: 14, height: 14)
                                Text(folder.name)
                                    .foregroundColor(ThemePalette.primaryText(for: scheme))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreate) {
                FolderDraftSheet(heading: "New folder", name: "", colorHex: DiaryPalette.folderSwatches[0].hex) { name, hex in
                    if let folder = diary.createFolder(name: name, colorHex: hex) {
                        diary.assign(noteIDs: noteIDs, to: folder.id)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DiaryInsightSection: View {
    @EnvironmentObject private var diary: DiaryViewModel
    @Environment(\.colorScheme) private var scheme
    var onAnalyse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(ThemePalette.primaryText(for: scheme))
                Spacer()
                Button(action: onAnalyse) {
                    Label("Analyse my notes", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundColor(ThemePalette.neonPurple)
                .disabled(diary.isAnalysing)
            }
            if diary.isAnalysing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Reflecting on your notes…")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
            if let message = diary.aiMessage {
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
            }
            if let insight = diary.insight {
                insightBody(insight)
            } else if !diary.isAnalysing {
                Text("A reflection appears here after you choose Analyse my notes. Nothing is sent until you confirm.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    .padding(14)
                    .neonCard()
            }
        }
    }

    @ViewBuilder
    private func insightBody(_ insight: DiaryInsight) -> some View {
        Text(insight.disclaimer)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(ThemePalette.secondaryText(for: scheme))
        Text("Last reflection \(insight.generatedAt.formatted(date: .abbreviated, time: .shortened)) · \(insight.noteCount) notes")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(ThemePalette.secondaryText(for: scheme))
        if insight.insufficient {
            Text(insight.explanation)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(ThemePalette.primaryText(for: scheme))
                .padding(16)
                .neonCard()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("One possible reading")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(ThemePalette.neonGreen)
                Text(insight.stage)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(insight.explanation)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(
                        colors: [ThemePalette.neonPurple, Color(red: 0.18, green: 0.08, blue: 0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            InsightBulletCard(title: "What went well", symbol: "checkmark.circle.fill", tint: ThemePalette.neonGreen, items: insight.wentWell)
            InsightBulletCard(title: "What went wrong", symbol: "exclamationmark.circle.fill", tint: ThemePalette.neonPink, items: insight.wentWrong)
            InsightBulletCard(title: "What to improve", symbol: "arrow.up.circle.fill", tint: ThemePalette.neonPurple, items: insight.toImprove)
            InsightBulletCard(title: "Suggested next actions", symbol: "arrow.right.circle.fill", tint: Color(red: 0.35, green: 0.75, blue: 1), items: insight.nextActions)
        }
    }
}

private struct InsightBulletCard: View {
    let title: String
    let symbol: String
    let tint: Color
    let items: [String]
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(tint)
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(tint).frame(width: 6, height: 6).padding(.top, 6)
                    Text(items[index])
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(ThemePalette.primaryText(for: scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonCard(cornerRadius: 18)
    }
}
