import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var otp = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var stage: Stage = .requestOTP
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    enum Stage {
        case requestOTP
        case resetPassword
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(systemName: stage == .requestOTP ? "lock.rotation" : "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                        .padding(.top, 20)
                    
                    Text(stage == .requestOTP ? "Forgot Password?" : "Reset Password")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text(stage == .requestOTP ? "Enter your email to receive a reset code." : "Enter the code sent to \(email) and your new password.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(spacing: 16) {
                    if stage == .requestOTP {
                        CustomTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    } else {
                        CustomTextField(icon: "number", placeholder: "6-Digit Code", text: $otp)
                            .keyboardType(.numberPad)
                        
                        CustomTextField(icon: "lock.fill", placeholder: "New Password", text: $newPassword, isSecure: true)
                        CustomTextField(icon: "lock.fill", placeholder: "Confirm New Password", text: $confirmPassword, isSecure: true)
                    }
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if let success = successMessage {
                    Text(success)
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Button {
                    stage == .requestOTP ? requestOTP() : resetPassword()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(stage == .requestOTP ? "Send Reset Code" : "Reset Password")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .disabled(isLoading || (stage == .requestOTP && email.isEmpty) || (stage == .resetPassword && (otp.count != 6 || newPassword.isEmpty || newPassword != confirmPassword)))
                .padding(.horizontal)
                
                if stage == .resetPassword {
                    Button {
                        withAnimation {
                            stage = .requestOTP
                            errorMessage = nil
                            successMessage = nil
                        }
                    } label: {
                        Text("Back to Email")
                            .font(.subheadline)
                            .foregroundColor(.pink)
                    }
                }
                
                Spacer()
            }
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
    
    private func requestOTP() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.forgotPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        stage = .resetPassword
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resetPassword() {
        if newPassword != confirmPassword {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.resetPassword(email: email, otp: otp, newPassword: newPassword)
                await MainActor.run {
                    isLoading = false
                    successMessage = "Password reset successfully! You can now log in."
                    // Wait a moment and then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
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

