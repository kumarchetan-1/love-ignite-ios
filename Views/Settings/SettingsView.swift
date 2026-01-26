import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @EnvironmentObject var store: StoreKitManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var scheme
    @State private var showAuthSheet = false
    
    var isSidebar: Bool = false
    
    // User preferences
    @AppStorage("haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("daily_reminders") private var dailyReminders: Bool = false
    @AppStorage("hide_explicit") private var hideExplicit: Bool = true
    @AppStorage("theme_preference") private var themePreference: String = "dark"
    
    @State private var showingReminderAlert = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    
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
                    // MARK: - Account Section
                Section {
                    if authManager.isAuthenticated {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(authManager.userName.prefix(1).uppercased())
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(authManager.userName)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                                Text(authManager.userEmail)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(ThemePalette.secondaryText(for: self.scheme))
                            }
                            
                            Spacer()
                            
                            Button {
                                showEditProfile = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding(.vertical, 8)

                        SettingsRow(icon: "key.fill", title: "Change Password", color: .pink) {
                            showChangePassword = true
                        }
                        
                        Button(role: .destructive) {
                            authManager.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                    .fontWeight(.semibold)
                            }
                        }
                    } else {
                        Button {
                            showAuthSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.pink)
                                VStack(alignment: .leading) {
                                    Text("Join Love Ignite")
                                        .font(.headline)
                                    Text("Sync progress across devices")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Account").font(.system(size: 14, weight: .bold)).textCase(.uppercase).tracking(1)
                }
                
                // MARK: - Subscription Section
                Section {
                    if store.hasSubscription {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color.green.opacity(0.1)).frame(width: 32, height: 32)
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                            Text("Premium Status")
                                .fontWeight(.medium)
                            Spacer()
                            Text("Active")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    } else {
                        Button {
                            store.showPaywall = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.yellow.opacity(0.1)).frame(width: 32, height: 32)
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                }
                                Text("Upgrade to Premium")
                                    .fontWeight(.bold)
                                    .foregroundColor(ThemePalette.primaryText(for: self.scheme))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        Task {
                            try? await AppStore.sync()
                            await store.updateSubscriptionState()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Membership").font(.system(size: 14, weight: .bold)).textCase(.uppercase).tracking(1)
                }
                
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
                    
                    Toggle(isOn: $hideExplicit) {
                        Label("Privacy Mode", systemImage: "eye.slash.fill")
                    }
                    .tint(.pink)
                    
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
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $store.showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(authManager)
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
