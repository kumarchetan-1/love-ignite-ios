import Foundation
import StoreKit
import Combine
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var showPaywall = false
    
    private let productIDs = ["com.loveignite.premium.forever"]
    private var transactionListener: Task<Void, Error>?
    
    var hasSubscription: Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    init() {
        transactionListener = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchaseStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    func fetchProducts() async {
        do {
            let fetchedProducts = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.products = fetchedProducts
            }
        } catch {
            // Silent fail for product fetching
        }
    }
    
    func purchase() async throws -> StoreKit.Transaction? {
        guard let product = products.first else { return nil }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // This is the real transaction from Apple
            await updatePurchaseStatus()
            await transaction.finish() 
            
            // Sync status to backend
            try await BackendService.shared.setPremiumStatus(isPremium: true)
            AuthenticationManager.shared.isPremium = true
            
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    func updatePurchaseStatus() async {
        var purchased: Set<String> = []
        
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        purchased.insert(transaction.productID)
                    }
                }
            }
        }
        
        self.purchasedProductIDs = purchased
        if !purchased.isEmpty {
            AuthenticationManager.shared.isPremium = true
        }
    }
    
    func updateSubscriptionState() async {
        await updatePurchaseStatus()
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchaseStatus()
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unverifiedTransaction
        case .verified(let safe):
            return safe
        }
    }
    
    enum StoreKitError: Error {
        case unverifiedTransaction
    }
}
