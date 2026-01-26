import SwiftUI

struct VerificationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var otp: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("Verify Email")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("We've sent a 6-digit code to\n\(authManager.userEmail)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // OTP Input
                TextField("000000", text: $otp)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .onChange(of: otp) { newValue in
                        if newValue.count > 6 {
                            otp = String(newValue.prefix(6))
                        }
                    }
                
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
                    verify()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verify")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(otp.count == 6 ? Color.pink : Color.pink.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .disabled(otp.count != 6 || isLoading)
                
                Button {
                    resend()
                } label: {
                    Text("Didn't receive a code? Resend")
                        .font(.subheadline)
                        .foregroundColor(.pink)
                }
                .disabled(isLoading)
                
                Spacer()
            }
            .padding(30)
            .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 450 : .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func verify() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.verifyEmail(otp: otp)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func resend() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                try await authManager.resendOTP()
                await MainActor.run {
                    isLoading = false
                    successMessage = "Code resent successfully!"
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

