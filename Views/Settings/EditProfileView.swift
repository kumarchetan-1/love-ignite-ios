import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.pink)
                        TextField("Name", text: $name)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.pink)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        updateProfile()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Changes")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || (name == authManager.userName && email == authManager.userEmail))
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = authManager.userName
                email = authManager.userEmail
            }
        }
    }
    
    private func updateProfile() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await authManager.updateProfile(name: name, email: email)
                await MainActor.run {
                    isLoading = false
                    successMessage = "Profile updated successfully!"
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

