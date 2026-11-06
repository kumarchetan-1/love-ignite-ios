import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var scheme
    
    var isSidebar: Bool = false
    
    // User preferences
    @AppStorage("haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("daily_reminders") private var dailyReminders: Bool = false
    @State private var showGuideGate = false
    @Environment(\.openURL) private var openURL
    @AppStorage("theme_preference") private var themePreference: String = "dark"
    
    @State private var showingReminderAlert = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var showMoodTracker = false
    @State private var showCycleTracker = false
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                content
            } else {
                NavigationView {
                    content
                        .navigationTitle("Settings")
                }
            }
        }
    }

    private var content: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: self.scheme)),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            .ignoresSafeArea() 
            
            VStack(spacing: 0) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    HStack {
                        Text("Settings")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                }
                
                List {
                // MARK: - Preferences
                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "waveform.path.ecg")
                    }
                    .tint(.pink)
                    
                    Toggle(isOn: $dailyReminders) {
                        Label("Daily Reminders", systemImage: "bell.badge.fill")
                    }
                    .tint(.pink)
                    .onChange(of: dailyReminders) { newValue in
                        showingReminderAlert = true
                    }
                    
                    Picker(selection: $themePreference) {
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                        Text("System").tag("system")
                    } label: {
                        Label("App Theme", systemImage: "paintpalette.fill")
                    }
                    .onChange(of: themePreference) { _ in
                        themeManager.themePreference = themePreference
                    }
                    
                } header: {
                    Text("Preferences").font(.system(size: 14, weight: .bold)).textCase(.uppercase).tracking(1)
                }

                // MARK: - Wellness
                Section {
                    Button {
                        showMoodTracker = true
                    } label: {
                        HStack {
                            Label("Mood Tracker", systemImage: "face.smiling.fill")
                                .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showCycleTracker = true
                    } label: {
                        HStack {
                            Label("Cycle & Mood Forecast", systemImage: "calendar.badge.clock")
                                .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Wellness").font(.system(size: 14, weight: .bold)).textCase(.uppercase).tracking(1)
                }
                
                // MARK: - Optional 18+ guide (opens an external website in Safari)
                Section {
                    Button {
                        showGuideGate = true
                    } label: {
                        HStack {
                            Label("Intimacy Guide (18+)", systemImage: "book.closed.fill")
                                .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Adults only").font(.system(size: 14, weight: .bold)).textCase(.uppercase).tracking(1)
                } footer: {
                    Text("Optional. Opens an external informational website in Safari. For adults 18 and over.")
                }

                // MARK: - Support & Legal
                Section {
                    SettingsLink(title: "Privacy Policy", icon: "hand.raised.fill", color: .blue) {
                        showPrivacySheet = true
                    }
                    
                    SettingsLink(title: "Terms of Service", icon: "doc.text.fill", color: .orange) {
                        showTermsSheet = true
                    }
                    
                    Link(destination: URL(string: "mailto:kumarchetan.npr@gmail.com")!) {
                        HStack {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                            .font(.system(.subheadline, design: .monospaced))
                    }
                } header: {
                    Text("About").font(.system(size: 14, weight: .bold)).textCase(.uppercase).tracking(1)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden) 
        }
    }
        .sheet(isPresented: $showTermsSheet) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showMoodTracker) {
            MoodTrackerView(showsCloseButton: true)
        }
        .sheet(isPresented: $showCycleTracker) {
            CycleTrackerView(showsCloseButton: true)
        }
        .alert("Are you 18 or older?", isPresented: $showGuideGate) {
            Button("I'm 18+, open in Safari") {
                if let url = URL(string: "https://love-ignite-web.kumarchetan-npr.workers.dev/guide") {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The Intimacy Guide is an external website with adult educational content. It opens in Safari.")
        }
        .alert("Daily reminders", isPresented: $showingReminderAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(dailyReminders ? "Reminders preference saved." : "Reminders turned off.")
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SettingsLink: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
