import Foundation

extension Product {
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // Use the current user's locale as a fallback if Product doesn't have a priceLocale
        formatter.locale = Locale.current 
        
        // Convert Decimal to NSNumber before formatting
        let priceNSNumber = price as NSNumber 
        
        return formatter.string(from: priceNSNumber) ?? "\(price)"
    }
}

// Assuming Product and its properties look something like this for context:
// You would need to define or ensure this struct exists in your project.
struct Product {
    let price: Decimal
    // If you need product-specific locales, add this:
    // let priceLocale: Locale 
}
