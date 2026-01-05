import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @EnvironmentObject var store: StoreKitManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var scheme
    @State private var showAuthSheet = false
    
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
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: ThemePalette.backgroundColors(for: scheme)),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea() 
                
                List {
                    // MARK: - Account Section
                    Section {
                        if authManager.isAuthenticated {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(authManager.userName.prefix(1).uppercased())
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(authManager.userName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(authManager.userEmail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                            .padding(.vertical, 4)

                            Button {
                                showChangePassword = true
                            } label: {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.pink)
                                    Text("Change Password")
                                }
                            }
                            
                            Button(role: .destructive) {
                                authManager.logout()
                            } label: {
                                Text("Log Out")
                            }
                        } else {
                            Button {
                                showAuthSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.pink)
                                    Text("Sign In / Sign Up")
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    } header: {
                        Text("Account")
                    }
                    
                    // MARK: - Subscription Section
                    Section {
                        if store.hasSubscription {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("Premium Active")
                                Spacer()
                            }
                        } else {
                            Button {
                                store.showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("Upgrade to Premium")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        Button("Restore Purchases") {
                            Task {
                                try? await AppStore.sync()
                                await store.updateSubscriptionState()
                            }
                        }
                    } header: {
                        Text("Membership")
                    }
                    
                    // MARK: - Preferences
                    Section {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                        Toggle("Daily Reminders", isOn: $dailyReminders)
                            .onChange(of: dailyReminders) { newValue in
                                showingReminderAlert = true
                            }
                        Toggle("Hide Explicit Content", isOn: $hideExplicit)
                            .onChange(of: hideExplicit) { _ in }
                        
                        Picker("Theme", selection: $themePreference) {
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                            Text("System").tag("system")
                        }
                        .onChange(of: themePreference) { _ in
                            themeManager.themePreference = themePreference
                        }
                        
                    } header: {
                        Text("Preferences")
                    }
                    
                    // MARK: - Support & Legal
                    Section {
                        Button("Privacy Policy") {
                            showPrivacySheet = true
                        }
                        
                        Button("Terms of Service") {
                            showTermsSheet = true
                        }
                        
                        Link("Contact Support", destination: URL(string: "mailto:kumarchetan.npr@gmail.com")!)
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("About")
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAuthSheet) {
                AuthenticationView()
            }
            .sheet(isPresented: $store.showPaywall) {
                PaywallView()
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
}
