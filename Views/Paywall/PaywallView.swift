import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeKitManager: StoreKitManager
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            // Neon Background
            Color(red: 0.05, green: 0.02, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("GO PREMIUM")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Unlock the full experience of Love Ignite")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "cloud.fill", text: "Cloud Sync Achievements", color: .blue)
                    FeatureRow(icon: "lock.open.fill", text: "Unlock All 150+ Tasks", color: .pink)
                    FeatureRow(icon: "heart.fill", text: "Support Development", color: .red)
                    FeatureRow(icon: "infinity", text: "One-time Purchase Forever", color: .purple)
                }
                .padding(.horizontal)

                Spacer()

                // Purchase Button
                if let product = storeKitManager.products.first {
                    Button {
                        Task {
                            isPurchasing = true
                            do {
                                _ = try await storeKitManager.purchase()
                                dismiss()
                            } catch {
                                // Silent fail
                            }
                            isPurchasing = false
                        }
                    } label: {
                        HStack {
                            if isPurchasing {
                        ProgressView()
                            .tint(.white)
                            } else {
                                Text("Upgrade for \(product.displayPrice)")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)
                } else if isPurchasing {
                    ProgressView().tint(.pink)
                } else {
                    VStack(spacing: 10) {
                        ProgressView().tint(.pink)
                        Text("Fetching products...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("Retry") {
                                Task {
                                await storeKitManager.fetchProducts()
                            }
                        }
                                                .font(.caption)
                        .foregroundColor(.pink)
                                        }
                                    }
                
                Button("Restore Purchase") {
                    Task {
                        await storeKitManager.updatePurchaseStatus()
                        if !storeKitManager.purchasedProductIDs.isEmpty {
                            try? await BackendService.shared.setPremiumStatus(isPremium: true)
                            dismiss()
                        }
                    }
                }
                .font(.footnote)
                .foregroundColor(.gray)
                
                Button("Maybe Later") {
                    dismiss()
                }
                        .font(.footnote)
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 20)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreKitManager.shared)
}
