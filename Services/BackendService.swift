import Foundation

class BackendService {
    static let shared = BackendService()
    
    // Change this to your GCP production URL later
    private let baseURL = "http://localhost:3000/api"
    
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
    
    func getProfile() async throws -> (email: String, name: String?, achievements: [String], unlockedCards: [String]) {
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
        let achievements = json?["achievements"] as? [String] ?? []
        let unlockedCards = json?["unlockedCards"] as? [String] ?? []
        
        return (email, name, achievements, unlockedCards)
    }
}

