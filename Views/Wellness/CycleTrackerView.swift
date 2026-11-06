import SwiftUI

struct CycleTrackerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    /// When shown as a root tab, there is nothing to dismiss. Only show Close when presented modally.
    var showsCloseButton: Bool = false

    @State private var profiles: [CycleProfile] = WellnessService.shared.loadCycleProfiles()
    @State private var selectedProfileId: String?
    @State private var showAddProfile = false
    @State private var editingProfile: CycleProfile?

    private var selectedIndex: Int {
        if let id = selectedProfileId, let idx = profiles.firstIndex(where: { $0.id == id }) { return idx }
        return 0
    }

    private var selectedProfile: CycleProfile {
        profiles.indices.contains(selectedIndex) ? profiles[selectedIndex] : CycleProfile(name: "Partner")
    }

    private var forecast: CycleForecast {
        WellnessService.shared.forecast(from: selectedProfile.settings)
    }

    private var history: [Date] {
        let s = selectedProfile.settings
        let h = s.periodStartHistory
        if !h.isEmpty { return h.sorted(by: >) }
        return [s.lastPeriodStart].sorted(by: >)
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
                        profileTabs
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        ForecastCard(forecast: forecast)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section("What this means") {
                        Text("Cycle is a personal tracker for menstrual cycle timing. Log each period start date and Love Ignite will estimate the next period and a PMS window based on your typical cycle length.")
                            .font(.footnote)
                            .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    }

                    Section("Period log") {
                        if history.isEmpty {
                            Text("No period logs yet.")
                                .foregroundColor(ThemePalette.secondaryText(for: scheme))
                        } else {
                            ForEach(history, id: \.self) { d in
                                HStack {
                                    Label {
                                        Text(d, style: .date)
                                    } icon: {
                                        Image(systemName: "drop.fill")
                                    }
                                    .labelStyle(.titleAndIcon)
                                    Spacer()
                                }
                            }
                            .onDelete(perform: deleteLogs)
                        }

                        Button {
                            logPeriodStart(Date())
                        } label: {
                            Label("Log period start as today", systemImage: "calendar.badge.plus")
                                .foregroundColor(ThemePalette.primaryText(for: scheme))
                        }
                    }

                    Section("Cycle settings") {
                        DatePicker(
                            "Last period start",
                            selection: Binding(
                                get: { selectedProfile.settings.lastPeriodStart },
                                set: { newDate in
                                    updateSettings { settings in
                                        settings.lastPeriodStart = newDate
                                    }
                                }
                            ),
                            displayedComponents: [.date]
                        )

                        Stepper(
                            "Cycle length: \(selectedProfile.settings.cycleLengthDays) days",
                            value: Binding(
                                get: { selectedProfile.settings.cycleLengthDays },
                                set: { v in updateSettings { $0.cycleLengthDays = v } }
                            ),
                            in: 20...40
                        )

                        Stepper(
                            "Period length: \(selectedProfile.settings.periodLengthDays) days",
                            value: Binding(
                                get: { selectedProfile.settings.periodLengthDays },
                                set: { v in updateSettings { $0.periodLengthDays = v } }
                            ),
                            in: 2...10
                        )
                    }

                    Section("Privacy") {
                        Text("Cycle data is stored on your device (and your iCloud key-value store if enabled).")
                            .font(.footnote)
                            .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Cycle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                }
            }
        }
        .onAppear {
            if selectedProfileId == nil, let first = profiles.first {
                selectedProfileId = first.id
            }
        }
        .sheet(isPresented: $showAddProfile) {
            AddCycleProfileSheet { profile in
                profiles.append(profile)
                WellnessService.shared.saveCycleProfiles(profiles)
                selectedProfileId = profile.id
            }
        }
        .sheet(item: $editingProfile) { profile in
            EditCycleProfileSheet(profile: profile) { updated in
                if let idx = profiles.firstIndex(where: { $0.id == updated.id }) {
                    profiles[idx] = updated
                    WellnessService.shared.saveCycleProfiles(profiles)
                }
            } onDelete: {
                deleteProfile(profile)
            }
        }
    }

    private func logPeriodStart(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        var s = selectedProfile.settings
        var h = s.periodStartHistory
        if !h.contains(where: { Calendar.current.isDate($0, inSameDayAs: day) }) {
            h.append(day)
        }
        h.sort(by: >)
        s.periodStartHistory = h
        s.lastPeriodStart = h.first ?? s.lastPeriodStart
        updateSettings(replacing: s)
    }

    private func deleteLogs(at offsets: IndexSet) {
        var h = history
        h.remove(atOffsets: offsets)
        var s = selectedProfile.settings
        s.periodStartHistory = h
        s.lastPeriodStart = h.first ?? s.lastPeriodStart
        updateSettings(replacing: s)
    }

    private func updateSettings(_ mutate: (inout CycleSettings) -> Void) {
        var s = selectedProfile.settings
        mutate(&s)
        s.cycleLengthDays = min(max(s.cycleLengthDays, 20), 40)
        s.periodLengthDays = min(max(s.periodLengthDays, 2), 10)
        updateSettings(replacing: s)
    }

    private func updateSettings(replacing s: CycleSettings) {
        var updated = profiles
        guard updated.indices.contains(selectedIndex) else { return }
        updated[selectedIndex].settings = s
        profiles = updated
        WellnessService.shared.saveCycleProfiles(updated)
    }

    private var profileTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(profiles) { p in
                    let selected = p.id == selectedProfileId
                    Button {
                        selectedProfileId = p.id
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.name)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            if !p.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(p.label)
                                    .font(.caption2)
                                    .opacity(0.75)
                            }
                        }
                        .foregroundColor(selected ? .white : ThemePalette.primaryText(for: scheme))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    selected
                                    ? AnyShapeStyle(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(ThemePalette.cardBackground(for: scheme).opacity(scheme == .dark ? 0.25 : 0.75))
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(selected ? 0.25 : 0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit") { editingProfile = p }
                        if profiles.count > 1 {
                            Button("Delete", role: .destructive) { deleteProfile(p) }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func deleteProfile(_ profile: CycleProfile) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == profile.id }
        WellnessService.shared.saveCycleProfiles(profiles)
        if selectedProfileId == profile.id {
            selectedProfileId = profiles.first?.id
        }
    }
}

private struct AddCycleProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var onAdd: (CycleProfile) -> Void

    @State private var name: String = ""
    @State private var label: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Form {
                    Section("Person") {
                        TextField("Name", text: $name)
                        TextField("Label (optional)", text: $label)
                    }
                    Section {
                        Text("Example labels: Partner, Sister, Mother")
                            .font(.footnote)
                            .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onAdd(CycleProfile(name: trimmed, label: label.trimmingCharacters(in: .whitespacesAndNewlines)))
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct EditCycleProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let profile: CycleProfile
    var onSave: (CycleProfile) -> Void
    var onDelete: () -> Void

    @State private var name: String
    @State private var label: String

    init(profile: CycleProfile, onSave: @escaping (CycleProfile) -> Void, onDelete: @escaping () -> Void) {
        self.profile = profile
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: profile.name)
        _label = State(initialValue: profile.label)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Form {
                    Section("Person") {
                        TextField("Name", text: $name)
                        TextField("Label (optional)", text: $label)
                    }
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete person", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        var p = profile
                        p.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        p.label = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(p)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ForecastCard: View {
    @Environment(\.colorScheme) private var scheme
    let forecast: CycleForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Forecast")
                    .font(.headline)
                    .foregroundColor(ThemePalette.primaryText(for: scheme))
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            Row(title: "Next period", value: "\(date(forecast.nextPeriodStart)) → \(date(forecast.nextPeriodEnd))")
            Row(title: "PMS window", value: "\(date(forecast.pmsStart)) → \(date(forecast.pmsEnd))")

            Text("This is an estimate based on your typical cycle length.")
                .font(.caption)
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
                .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ThemePalette.cardBackground(for: scheme).opacity(scheme == .dark ? 0.35 : 0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(scheme == .dark ? 0.10 : 0.25), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private func date(_ d: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: d)
    }
}

private struct Row: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(ThemePalette.primaryText(for: scheme))
            Spacer()
        }
    }
}

