import Foundation
import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @AppStorage("is_logged_in") var isAuthenticated: Bool = false
    @AppStorage("user_email") var userEmail: String = ""
    @AppStorage("user_id") var userId: String = ""
    @AppStorage("user_name") var userName: String = ""
    
    private let baseURL = "http://localhost:3000/api/auth"
    
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
        let name = json?["name"] as? String ?? (email.components(separatedBy: "@").first ?? "User")
        
        await MainActor.run {
            BackendService.shared.setToken(token)
            self.userEmail = email
            self.userId = userId
            self.userName = name
            self.isAuthenticated = true
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
        
        await MainActor.run {
            BackendService.shared.setToken(token)
            self.userEmail = email
            self.userId = userId
            self.userName = name
            self.isAuthenticated = true
        }
    }
    
    func logout() {
        BackendService.shared.clearToken()
        isAuthenticated = false
        userEmail = ""
        userId = ""
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

