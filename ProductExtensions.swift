import Foundation
import StoreKit // Import StoreKit to refer to its types

// Introduce a typealias within this file to unequivocally refer to StoreKit.SKProduct.
// This helps resolve any potential type ambiguity and correctly aligns with the
// 'priceLocale' property which is part of StoreKit.SKProduct (StoreKit 1).
private typealias SKProductAlias = StoreKit.SKProduct

extension SKProductAlias { // Now extend the typealias instead of directly StoreKit.Product
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // SKProductAlias now correctly refers to StoreKit.SKProduct, which has `priceLocale`.
        formatter.locale = self.priceLocale 
        
        // SKProduct.price is an NSDecimalNumber, which is a subclass of NSNumber,
        // so the cast is appropriate.
        let priceNSNumber = price as NSNumber 
        
        return formatter.string(from: priceNSNumber) ?? "\(price)"
    }
}

// The local 'struct Product' that was previously defined here has been removed.
// It was shadowing 'StoreKit.Product' and causing type conflicts.
// If a custom 'Product' type is truly needed for other purposes, it should be
// given a distinct name or placed within a separate namespace to avoid clashes.
