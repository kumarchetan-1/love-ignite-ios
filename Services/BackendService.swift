import Foundation

class BackendService {
    static let shared = BackendService()
    
    // DigitalOcean Production URL
    private let baseURL = "https://api.loveignite.chetankumar.me"
    
    private var token: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }
    
    func setToken(_ token: String) {
        self.token = token
    }
    
    func clearToken() {
        self.token = nil
    }
    
    func updateProfile(name: String?, email: String?) async throws {
        guard let token = token else { return }
        
        let url = URL(string: "\(baseURL)/user/update-profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: String] = [:]
        if let name = name { body["name"] = name }
        if let email = email { body["email"] = email }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to update profile"])
        }
    }
    
    func changePassword(current: String, new: String) async throws {
        guard let token = token else { return }
        
        let url = URL(string: "\(baseURL)/user/change-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["currentPassword": current, "newPassword": new]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to change password"])
        }
    }
    
    func forgotPassword(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/forgot-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to send reset code"])
        }
    }
    
    func resetPassword(email: String, otp: String, newPassword: String) async throws {
        let url = URL(string: "\(baseURL)/auth/reset-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "otp": otp, "newPassword": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to reset password"])
        }
    }
    
    func setPremiumStatus(isPremium: Bool) async throws {
        guard let token = token else { return }
        
        let url = URL(string: "\(baseURL)/user/set-premium")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["isPremium": isPremium]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to update premium status"])
        }
    }
    
    func syncAchievements(achievementIds: [String]) async throws {
        guard let token = token else { return }
        
        let url = URL(string: "\(baseURL)/user/sync-achievements")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["achievements": achievementIds]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sync achievements"])
        }
    }
    
    func syncUnlockedCards(cardIds: [String]) async throws {
        guard let token = token else { return }
        
        let url = URL(string: "\(baseURL)/user/sync-cards")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["cardIds": cardIds]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sync cards"])
        }
    }
    
    func getProfile() async throws -> (email: String, name: String?, isPremium: Bool, isVerified: Bool, achievements: [String], unlockedCards: [String]) {
        guard let token = token else {
            throw NSError(domain: "BackendService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let url = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "BackendService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch profile"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let email = json?["email"] as? String ?? ""
        let name = json?["name"] as? String
        let isPremium = json?["isPremium"] as? Bool ?? false
        let isVerified = json?["isVerified"] as? Bool ?? false
        let achievements = json?["achievements"] as? [String] ?? []
        let unlockedCards = json?["unlockedCards"] as? [String] ?? []
        
        return (email, name, isPremium, isVerified, achievements, unlockedCards)
    }
}
