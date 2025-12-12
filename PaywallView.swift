import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var store: StoreKitManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Premium Kamasutra Pack")
                .font(.title2).bold()
            Text("Unlock all premium positions, extra hot challenges and bonus questions.")
                .font(.body)
                .multilineTextAlignment(.center)

            if store.products.isEmpty {
                Button(
                    action: {
                        Task { await store.requestProducts() }
                    },
                    label: {
                        Text("Load products")
                    }
                )
            } else {
                ForEach(store.products, id: \.productIdentifier) { p in // Changed id to \.productIdentifier
                    Button(action: {
                        Task {
                            do {
                                _ = try await store.purchase(p)
                                // after purchase, store.updateSubscriptionState would update hasSubscription
                                store.showPaywall = false
                            } catch {
                                print("purchase error", error)
                            }
                        }
                    }, label: {
                        HStack {
                            Text(p.displayName)
                            Spacer()
                            Text(p.displayPrice)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    })
                }
            }

            Button("Close") { dismiss() }
                .padding(.top, 8)
        }
        .padding()
        .background(LinearGradient(colors: [Color("cardBg1"), Color("cardBg2")], startPoint: .top, endPoint: .bottom))
        .cornerRadius(14)
        .padding()
    }
}
