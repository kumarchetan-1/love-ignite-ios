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

    private var phase: CyclePhaseSnapshot {
        CyclePhaseSnapshot.make(settings: selectedProfile.settings)
    }

    private var timeline: [PeriodTimelineItem] {
        PeriodTimelineItem.make(from: history, periodLengthDays: selectedProfile.settings.periodLengthDays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        profileTabs
                        phaseHero
                        ForecastCard(forecast: forecast)
                        meaningCard
                        settingsCard
                        privacyCard
                        timelineSection
                        Spacer().frame(height: 120)
                    }
                    .padding(.top, 8)
                }
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

    private var phaseHero: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(ThemePalette.neonGreen)
                Text(phase.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(phase.detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.16), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: phase.progress)
                    .stroke(ThemePalette.neonGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ThemePalette.neonGreen.opacity(0.8), radius: 6)
                Text(phase.dayLabel)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 78, height: 78)
            .accessibilityLabel(phase.accessibility)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.36, green: 0.16, blue: 0.72),
                        Color(red: 0.10, green: 0.16, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(ThemePalette.neonGreen.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var meaningCard: some View {
        Text("This estimate uses the cycle length and period length you set for \(selectedProfile.name). It is a personal date sketch, not medical advice or a fertility prediction.")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(ThemePalette.secondaryText(for: scheme))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassmorphic(cornerRadius: 18)
            .padding(.horizontal, 16)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycle settings")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(ThemePalette.primaryText(for: scheme))
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassmorphic(cornerRadius: 18)
        .padding(.horizontal, 16)
    }

    private var privacyCard: some View {
        Text("Cycle data is stored on your device and in your iCloud key-value store. It is not sent to Gemini.")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(ThemePalette.secondaryText(for: scheme))
            .padding(.horizontal, 20)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous periods")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(ThemePalette.primaryText(for: scheme))
            Text("Newest first. End dates use the period length you set, because only start dates are logged. Flow and symptoms are not tracked.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ThemePalette.secondaryText(for: scheme))

            Button {
                logPeriodStart(Date())
                Haptics.success()
            } label: {
                Label("Log period start as today", systemImage: "calendar.badge.plus")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemePalette.neonPurple)

            if timeline.isEmpty {
                Text("No period logs yet.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassmorphic(cornerRadius: 18)
            } else {
                ForEach(timeline) { item in
                    timelineRow(item, isLast: item.start == timeline.last?.start)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func timelineRow(_ item: PeriodTimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(item.isLatest ? ThemePalette.neonGreen : ThemePalette.neonPurple)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))
                if !isLast {
                    Rectangle()
                        .fill(ThemePalette.neonPurple.opacity(0.35))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 14)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(item.start.formatted(date: .abbreviated, time: .omitted)) – \(item.estimatedEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ThemePalette.primaryText(for: scheme))
                Text(item.isLatest ? "Estimated end · \(selectedProfile.settings.periodLengthDays) day period" : "Estimated window · \(selectedProfile.settings.periodLengthDays) day period")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(ThemePalette.secondaryText(for: scheme))
                Text(item.lengthLine)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(scheme == .dark ? ThemePalette.neonGreen : Color(red: 0.0, green: 0.45, blue: 0.22))
                if selectedProfile.settings.periodStartHistory.contains(where: { Calendar.current.isDate($0, inSameDayAs: item.start) }) {
                    Button("Remove this start") {
                        deleteStart(item.start)
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(ThemePalette.neonPink)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassmorphic(cornerRadius: 18)
        }
    }

    private func deleteStart(_ date: Date) {
        let calendar = Calendar.current
        var h = history.filter { !calendar.isDate($0, inSameDayAs: date) }
        h.sort(by: >)
        var s = selectedProfile.settings
        s.periodStartHistory = h
        s.lastPeriodStart = h.first ?? s.lastPeriodStart
        updateSettings(replacing: s)
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
                    .foregroundStyle(LinearGradient(colors: [ThemePalette.neonGreen, ThemePalette.neonPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            Row(title: "Next period", value: "\(date(forecast.nextPeriodStart)) → \(date(forecast.nextPeriodEnd))")
            Row(title: "PMS window", value: "\(date(forecast.pmsStart)) → \(date(forecast.pmsEnd))")

            Text("This is an estimate based on your typical cycle length.")
                .font(.caption)
                .foregroundColor(ThemePalette.secondaryText(for: scheme))
                .padding(.top, 2)
        }
        .padding(16)
        .glassmorphic(cornerRadius: 20, opacity: 0.18, borderOpacity: 0.45)
        .padding(.horizontal, 16)
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

private struct CyclePhaseSnapshot {
    var title: String
    var detail: String
    var progress: Double
    var dayLabel: String
    var accessibility: String

    static func make(settings: CycleSettings, today: Date = Date(), calendar: Calendar = .current) -> CyclePhaseSnapshot {
        let start = calendar.startOfDay(for: settings.lastPeriodStart)
        let day = (calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: today)).day ?? 0) + 1
        let cycle = max(settings.cycleLengthDays, 1)
        let period = max(settings.periodLengthDays, 1)
        let progress = min(Double(max(day, 1)) / Double(cycle), 1)
        let dayLabel = "\(max(day, 1))"
        if day < 1 {
            return CyclePhaseSnapshot(
                title: "Before this log",
                detail: "The last period start you set is still in the future.",
                progress: 0,
                dayLabel: "—",
                accessibility: "Last period start is in the future"
            )
        }
        if day <= period {
            return CyclePhaseSnapshot(
                title: "Menstrual",
                detail: "Inside the \(period)-day period length set for this person.",
                progress: progress,
                dayLabel: dayLabel,
                accessibility: "Day \(dayLabel), menstrual"
            )
        }
        if day > cycle {
            return CyclePhaseSnapshot(
                title: "Past the usual gap",
                detail: "The \(cycle)-day cycle length you set has passed. Logging the next period start moves the estimate.",
                progress: 1,
                dayLabel: dayLabel,
                accessibility: "Day \(dayLabel), past the cycle length you set"
            )
        }
        let ovulation = max(cycle - 14, period + 1)
        if abs(day - ovulation) <= 1 {
            return CyclePhaseSnapshot(
                title: "Ovulation window",
                detail: "A rough middle of the cycle length you set. This is not a fertility prediction.",
                progress: progress,
                dayLabel: dayLabel,
                accessibility: "Day \(dayLabel), estimated ovulation window"
            )
        }
        if day < ovulation {
            return CyclePhaseSnapshot(
                title: "Follicular",
                detail: "After the period length you set, and before the estimated middle of the cycle.",
                progress: progress,
                dayLabel: dayLabel,
                accessibility: "Day \(dayLabel), follicular"
            )
        }
        return CyclePhaseSnapshot(
            title: "Luteal",
            detail: "The later part of the cycle length you set, before the next estimated period.",
            progress: progress,
            dayLabel: dayLabel,
            accessibility: "Day \(dayLabel), luteal"
        )
    }
}

private struct PeriodTimelineItem: Identifiable {
    let start: Date
    let estimatedEnd: Date
    let isLatest: Bool
    let lengthLine: String

    var id: TimeInterval { start.timeIntervalSince1970 }

    static func make(from history: [Date], periodLengthDays: Int, today: Date = Date(), calendar: Calendar = .current) -> [PeriodTimelineItem] {
        var seen = Set<TimeInterval>()
        let starts = history.map { calendar.startOfDay(for: $0) }.filter { seen.insert($0.timeIntervalSince1970).inserted }
        return starts.enumerated().map { index, start in
            let typicalEnd = calendar.date(byAdding: .day, value: max(periodLengthDays - 1, 0), to: start) ?? start
            let newerStart = index > 0 ? starts[index - 1] : nil
            var end = typicalEnd
            if let newerStart, let dayBefore = calendar.date(byAdding: .day, value: -1, to: newerStart), dayBefore < end {
                end = max(start, dayBefore)
            }
            let lengthLine: String
            if let newerStart, let gap = calendar.dateComponents([.day], from: start, to: newerStart).day, gap > 0 {
                lengthLine = "Cycle length \(gap) days"
            } else {
                let soFar = (calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: today)).day ?? 0) + 1
                lengthLine = "Current cycle · day \(max(soFar, 1))"
            }
            return PeriodTimelineItem(start: start, estimatedEnd: end, isLatest: index == 0, lengthLine: lengthLine)
        }
    }
}

