import Foundation
import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @AppStorage("is_logged_in") var isAuthenticated: Bool = false
    @AppStorage("user_email") var userEmail: String = ""
    @AppStorage("user_name") var userName: String = ""
    
    func login(email: String, password: String) async throws {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        await MainActor.run {
            self.userEmail = email
            self.userName = email.components(separatedBy: "@").first ?? "User"
            self.isAuthenticated = true
        }
    }
    
    func signup(name: String, email: String, password: String) async throws {
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            throw AuthError.invalidInput
        }
        
        await MainActor.run {
            self.userEmail = email
            self.userName = name
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        isAuthenticated = false
        userEmail = ""
        userName = ""
    }
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case invalidInput
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials: return "Invalid email or password."
            case .invalidInput: return "Please fill in all fields."
            }
        }
    }
}

