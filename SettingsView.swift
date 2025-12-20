import SwiftUI
import StoreKit

struct SettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @EnvironmentObject var store: StoreKitManager
    @State private var showAuthSheet = false
    
    // User preferences
    @AppStorage("haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("daily_reminders") private var dailyReminders: Bool = false
    @AppStorage("hide_explicit") private var hideExplicit: Bool = false
    @AppStorage("theme_preference") private var themePreference: String = "dark"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("bg1").ignoresSafeArea() // Fallback bg if list is transparent
                
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
                            }
                            .padding(.vertical, 4)
                            
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
                                if store.canEraseAll {
                                    Image(systemName: "trash.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
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
                        Toggle("Hide Explicit Content", isOn: $hideExplicit)
                        
                        Picker("Theme", selection: $themePreference) {
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                            Text("System").tag("system")
                        }
                        
                    } header: {
                        Text("Preferences")
                    }
                    
                    // MARK: - Support & Legal
                    Section {
                        Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
                        Link("Terms of Service", destination: URL(string: "https://yourwebsite.com/terms")!)
                        Link("Contact Support", destination: URL(string: "mailto:support@yourapp.com")!)
                        
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
        }
    }
}
