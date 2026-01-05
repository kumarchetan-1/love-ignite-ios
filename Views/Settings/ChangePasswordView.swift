import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    SecureField("Current Password", text: $currentPassword)
                }
                
                Section(header: Text("New Password")) {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
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
                        handleChangePassword()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Change Password")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isLoading || currentPassword.isEmpty || newPassword.isEmpty || newPassword != confirmPassword)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleChangePassword() {
        if newPassword != confirmPassword {
            errorMessage = "New passwords do not match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await authManager.changePassword(current: currentPassword, new: newPassword)
                await MainActor.run {
                    isLoading = false
                    successMessage = "Password changed successfully!"
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
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

