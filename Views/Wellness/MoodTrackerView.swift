import SwiftUI

struct MoodTrackerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    /// When shown as a root tab, there is nothing to dismiss. Only show Close when presented modally.
    var showsCloseButton: Bool = false

    @State private var entries: [MoodEntry] = WellnessService.shared.loadMoodEntries()
    @State private var showAdd = false
    @State private var editingEntry: MoodEntry?

    private var sortedEntries: [MoodEntry] {
        entries.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                List {
                    Section {
                        if sortedEntries.isEmpty {
                            VStack(spacing: 8) {
                                Text("No mood entries yet")
                                    .font(.headline)
                                    .foregroundColor(ThemePalette.primaryText(for: scheme))
                                Text("Track your mood to spot patterns together.")
                                    .font(.subheadline)
                                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(sortedEntries) { e in
                                Button {
                                    editingEntry = e
                                } label: {
                                    MoodRow(entry: e)
                                }
                                .buttonStyle(.plain)
                                    .listRowBackground(ThemePalette.cardBackground(for: scheme).opacity(scheme == .dark ? 0.35 : 0.9))
                            }
                            .onDelete(perform: delete)
                        }
                    } header: {
                        Text("Mood Tracker")
                            .font(.system(size: 14, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMoodEntrySheet { entry in
                    entries.append(entry)
                    WellnessService.shared.saveMoodEntries(entries)
                }
            }
            .sheet(item: $editingEntry) { entry in
                EditMoodEntrySheet(entry: entry) { updated in
                    if let idx = entries.firstIndex(where: { $0.id == updated.id }) {
                        entries[idx] = updated
                        WellnessService.shared.saveMoodEntries(entries)
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { sortedEntries[$0].id }
        entries.removeAll { idsToDelete.contains($0.id) }
        WellnessService.shared.saveMoodEntries(entries)
    }
}

private struct EditMoodEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let entry: MoodEntry
    var onSave: (MoodEntry) -> Void

    @State private var date: Date
    @State private var moodScore: Int
    @State private var tagsText: String
    @State private var note: String

    init(entry: MoodEntry, onSave: @escaping (MoodEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _date = State(initialValue: entry.date)
        _moodScore = State(initialValue: entry.moodScore)
        _tagsText = State(initialValue: entry.tags.joined(separator: ", "))
        _note = State(initialValue: entry.note)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Form {
                    Section("Entry") {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                        Stepper("Mood: \(moodScore)", value: $moodScore, in: 1...5)
                        TextField("Tags (comma separated)", text: $tagsText)
                        TextField("Note (optional)", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let tags = tagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        onSave(MoodEntry(id: entry.id, date: date, moodScore: moodScore, tags: tags, note: note))
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MoodRow: View {
    @Environment(\.colorScheme) private var scheme
    let entry: MoodEntry

    private var moodColor: Color {
        switch entry.moodScore {
        case 1: return Color.red.opacity(0.85)
        case 2: return Color.orange.opacity(0.85)
        case 3: return Color.yellow.opacity(0.85)
        case 4: return Color.pink.opacity(0.85)
        default: return Color.purple.opacity(0.85)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(moodColor.opacity(scheme == .dark ? 0.35 : 0.22))
                .overlay(
                    Text("\(entry.moodScore)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(moodColor)
                )
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date)
                    .font(.headline)
                    .foregroundColor(ThemePalette.primaryText(for: scheme))

                if !entry.tags.isEmpty {
                    Text(entry.tags.joined(separator: " · "))
                        .font(.caption)
                        .foregroundColor(ThemePalette.secondaryText(for: scheme))
                        .lineLimit(1)
                }

                if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(entry.note)
                        .font(.subheadline)
                        .foregroundColor(ThemePalette.secondaryText(for: scheme))
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct AddMoodEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var onSave: (MoodEntry) -> Void

    @State private var date = Date()
    @State private var moodScore: Int = 3
    @State private var tagsText: String = ""
    @State private var note: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Form {
                    Section("Entry") {
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                        Stepper("Mood: \(moodScore)", value: $moodScore, in: 1...5)
                        TextField("Tags (comma separated)", text: $tagsText)
                        TextField("Note (optional)", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let tags = tagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        onSave(MoodEntry(date: date, moodScore: moodScore, tags: tags, note: note))
                        dismiss()
                    }
                }
            }
        }
    }
}

