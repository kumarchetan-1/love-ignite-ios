import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var onSuccess: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color("bg1"), Color("bg2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
                            .padding(.top, 40)
                        
                        Text(isLoginMode ? "Welcome Back" : "Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(isLoginMode ? "Sign in to continue your love journey" : "Join us to unlock romantic memories")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        if !isLoginMode {
                            CustomTextField(icon: "person.fill", placeholder: "Your Name", text: $name)
                        }
                        
                        CustomTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        CustomTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
                    }
                    .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Action Button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isLoginMode ? "Log In" : "Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                                .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
                    // Toggle Mode
                    Button {
                        withAnimation {
                            isLoginMode.toggle()
                            errorMessage = nil
                        }
                    } label: {
                        HStack {
                            Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                                .foregroundColor(.white.opacity(0.6))
                            Text(isLoginMode ? "Sign Up" : "Log In")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .font(.footnote)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private func handleAuth() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isLoginMode {
                    try await authManager.login(email: email, password: password)
                } else {
                    try await authManager.signup(name: name, email: email, password: password)
                }
                
                // Success
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    onSuccess?()
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

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 24)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .foregroundColor(.white)
    }
}

