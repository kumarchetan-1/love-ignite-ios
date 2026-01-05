import Foundation

class CloudSyncService {
    static let shared = CloudSyncService()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(kvStoreChanged), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
    }

    @objc private func kvStoreChanged(_ note: Notification) {
        // handle external changes if needed
    }
}