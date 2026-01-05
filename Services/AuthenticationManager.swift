import Foundation
import SwiftUI
import Combine
import GoogleSignIn

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @AppStorage("is_logged_in") private var persistedIsAuthenticated: Bool = false
    @Published var isAuthenticated: Bool = false
    
    @AppStorage("user_email") var userEmail: String = ""
    @AppStorage("user_id") var userId: String = ""
    @AppStorage("user_name") var userName: String = ""
    @AppStorage("is_premium") var isPremium: Bool = false
    @AppStorage("is_verified") var isVerified: Bool = false
    
    @Published var needsVerification: Bool = false
    
    private init() {
        self.isAuthenticated = persistedIsAuthenticated
    }
    
    private let baseURL = "https://api.loveignite.chetankumar.me/auth"
    
    func login(email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let token = json?["token"] as? String ?? ""
        let userId = json?["userId"] as? String ?? ""
        let isPremium = json?["isPremium"] as? Bool ?? false
        let isVerified = json?["isVerified"] as? Bool ?? false
        let name = json?["name"] as? String ?? (email.components(separatedBy: "@").first ?? "User")
        
        await MainActor.run {
            BackendService.shared.setToken(token)
            self.userEmail = email
            self.userId = userId
            self.userName = name
            self.isPremium = isPremium
            self.isVerified = isVerified
            
            if !isVerified {
                self.needsVerification = true
            } else {
                self.persistedIsAuthenticated = true
                self.isAuthenticated = true
            }
        }
    }
    
    func signup(name: String, email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password, "name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidInput
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let token = json?["token"] as? String ?? ""
        let userId = json?["userId"] as? String ?? ""
        let isPremium = json?["isPremium"] as? Bool ?? false
        let isVerified = json?["isVerified"] as? Bool ?? false
        
        await MainActor.run {
            BackendService.shared.setToken(token)
            self.userEmail = email
            self.userId = userId
            self.userName = name
            self.isPremium = isPremium
            self.isVerified = isVerified
            self.needsVerification = true 
        }
    }
    
    func googleLogin() async throws {
        // Programmatic configuration as a fallback for missing Info.plist
        let config = GIDConfiguration(clientID: "664247776849-c0jfc1svnq5dfko7h5taiq2i1jj5552j.apps.googleusercontent.com")
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.custom("Could not find root view controller")
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.custom("Could not get ID token from Google")
        }
        
        let url = URL(string: "\(baseURL)/google")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["idToken": idToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.custom("Google login failed on backend")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let token = json?["token"] as? String ?? ""
        let userId = json?["userId"] as? String ?? ""
        let isPremium = json?["isPremium"] as? Bool ?? false
        let isVerified = json?["isVerified"] as? Bool ?? true // Google accounts are usually verified
        let name = json?["name"] as? String ?? result.user.profile?.name ?? "User"
        let email = json?["email"] as? String ?? result.user.profile?.email ?? ""
        
        await MainActor.run {
            BackendService.shared.setToken(token)
            self.userEmail = email
            self.userId = userId
            self.userName = name
            self.isPremium = isPremium
            self.isVerified = isVerified
            self.persistedIsAuthenticated = true
            self.isAuthenticated = true
            self.needsVerification = false
        }
    }
    
    func verifyEmail(otp: String) async throws {
        let url = URL(string: "\(baseURL)/verify-email")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": userId, "otp": otp]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.custom("Invalid or expired verification code.")
        }
        
        await MainActor.run {
            self.isVerified = true
            self.needsVerification = false
            self.persistedIsAuthenticated = true
            self.isAuthenticated = true
        }
    }
    
    func resendOTP() async throws {
        let url = URL(string: "\(baseURL)/resend-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.custom("Failed to resend code.")
        }
    }

    func updateProfile(name: String?, email: String?) async throws {
        try await BackendService.shared.updateProfile(name: name, email: email)
        await MainActor.run {
            if let name = name { self.userName = name }
            if let email = email { self.userEmail = email }
        }
    }

    func changePassword(current: String, new: String) async throws {
        try await BackendService.shared.changePassword(current: current, new: new)
    }

    func forgotPassword(email: String) async throws {
        try await BackendService.shared.forgotPassword(email: email)
    }

    func resetPassword(email: String, otp: String, newPassword: String) async throws {
        try await BackendService.shared.resetPassword(email: email, otp: otp, newPassword: newPassword)
    }
    
    func logout() {
        BackendService.shared.clearToken()
        persistedIsAuthenticated = false
        isAuthenticated = false
        userEmail = ""
        userId = ""
        userName = ""
        isPremium = false
        isVerified = false
        needsVerification = false
    }
    
    func fetchProfile() async {
        do {
            let profile = try await BackendService.shared.getProfile()
            await MainActor.run {
                self.userName = profile.name ?? ""
                self.isPremium = profile.isPremium
                self.isVerified = profile.isVerified
                self.userEmail = profile.email
            }
        } catch {
            // Silent fail
        }
    }
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case invalidInput
        case custom(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials: return "Invalid email or password."
            case .invalidInput: return "Please check your details and try again."
            case .custom(let message): return message
            }
        }
    }
}
