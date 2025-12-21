import Foundation
import Combine
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var hasSubscription: Bool = false
    @Published var canEraseAll: Bool = false
    @Published var showPaywall: Bool = false
    @Published var products: [Product] = []
    
    // MARK: - Configuration
    // These must match exactly what you set in App Store Connect
    public let productIDs: Set<String> = [
        "com.yourapp.monthly",   // e.g. $4.99 / month
        "com.yourapp.yearly",    // e.g. $29.99 / year
        "com.yourapp.lifetime"   // The $30 / ₹499 plan (Unlocks Everything + Erase All)
    ]
    
    private init() {
        // Kick off initial product request and subscription check
        Task {
            await requestProducts()
            await checkSubscription()
        }
    }
    
    func requestProducts() async {
        do {
            // Sort products by price to keep UI consistent
            let fetchedProducts = try await Product.products(for: productIDs)
            self.products = fetchedProducts.sorted(by: { $0.price < $1.price })
            print("Fetched products: \(self.products.map { $0.id })")
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func checkSubscription() async {
        var hasActiveSub = false
        var hasErase = false
        
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                print("Found active entitlement: \(transaction.productID)")
                
                // LIFETIME: Unlocks EVERYTHING (Subscription features + Erase button)
                if transaction.productID == "com.yourapp.lifetime" {
                    hasActiveSub = true
                    hasErase = true
                }
                // SUBSCRIPTION: Unlocks content only
                else if ["com.yourapp.monthly", "com.yourapp.yearly"].contains(transaction.productID) {
                    hasActiveSub = true
                }
                // ERASE ONLY (If you ever wanted to sell it separately, though user implies it's in the $30 plan)
                else if transaction.productID == "com.yourapp.eraseall" {
                    hasErase = true
                }
            }
        }
        
        // Update published properties on main thread
        self.hasSubscription = hasActiveSub
        self.canEraseAll = hasErase
    }
    
    func updateSubscriptionState() async {
        await checkSubscription()
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        print("Attempting to purchase product: \(product.id)")
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionState()
            await transaction.finish() 
            return transaction
            
        case .pending:
            print("Purchase is pending.")
            return nil
            
        case .userCancelled:
            print("Purchase was cancelled by the user.")
            return nil
            
        @unknown default:
            print("Unknown purchase result.")
            return nil
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let unverifiedTransaction, let error):
            print("Unverified transaction: \(unverifiedTransaction), error: \(error)")
            throw StoreKitError.unverifiedTransaction
        case .verified(let verifiedTransaction):
            return verifiedTransaction
        }
    }
    
    enum StoreKitError: Error {
        case unverifiedTransaction
        case productNotFound
    }
}
