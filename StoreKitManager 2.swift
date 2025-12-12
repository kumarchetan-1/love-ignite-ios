// Ensure 'import StoreKit' is at the top of your StoreKitManager.swift file.
import StoreKit

// ... other code ...

func purchase(_ product: StoreKit.Product) async throws -> StoreKit.Transaction? {
    let result = try await product.purchase()
    switch result {
    case .success(let verification):
        let transaction = try checkVerified(verification)
        await updateSubscriptionState() // Assuming updateSubscriptionState() is defined elsewhere
        return transaction
    case .pending:
        // The purchase is pending, e.g., waiting for parental approval or payment processing.
        print("Purchase is pending.")
        return nil
    case .userCancelled:
        // The user explicitly cancelled the purchase.
        print("Purchase was cancelled by the user.")
        return nil
    case .failed(let error):
        // The purchase failed with an error.
        print("Purchase failed with error: \(error.localizedDescription)")
        throw error // Re-throw the error or handle it as appropriate for your app
    @unknown default:
        // Handle any unknown future cases of Product.PurchaseResult that StoreKit might add.
        print("Unknown purchase result.")
        return nil
    }
}
