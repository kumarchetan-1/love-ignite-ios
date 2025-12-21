import Foundation

protocol StorageServiceProtocol {
    func save<T: Codable>(_ object: T, for key: String)
    func load<T: Codable>(_ type: T.Type, for key: String) -> T?
    func remove(key: String)
}

class StorageService: StorageServiceProtocol {
    static let shared = StorageService()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func save<T: Codable>(_ object: T, for key: String) {
        do {
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: key)
            // iCloud sync
            NSUbiquitousKeyValueStore.default.set(data, forKey: key)
            NSUbiquitousKeyValueStore.default.synchronize()
        } catch {
            print("StorageService: Failed to save object for key '\(key)': \(error)")
        }
    }

    func load<T: Codable>(_ type: T.Type, for key: String) -> T? {
        // First try iCloud (ubiquitous) then fallback to UserDefaults
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: key) {
            do {
                return try decoder.decode(type, from: data)
            } catch {
                print("StorageService: Failed to decode iCloud data for key '\(key)': \(error)")
                // Fallback to local if cloud data is corrupt
            }
        }
        
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("StorageService: Failed to decode local data for key '\(key)': \(error)")
            return nil
        }
    }
    
    func remove(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
