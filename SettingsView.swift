import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Haptics", isOn: .constant(true))
                    Button("Reset Progress") {
                        UserDefaults.standard.removeObject(forKey: "revealed_v1")
                        UserDefaults.standard.removeObject(forKey: "achievements_v1")
                    }
                }
                Section(header: Text("Subscription")) {
                    Text("Unlock Bonus Questions & Extra Hot Tasks")
                    Button("Manage Subscription") {
                        // integrate StoreKit
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}