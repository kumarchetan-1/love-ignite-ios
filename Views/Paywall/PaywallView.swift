import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var store: StoreKitManager
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var scheme
    
    @State private var isAnimating = false
    @State private var showAuthSheet = false
    
    private var isAuthed: Bool { authManager.isAuthenticated }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: ThemePalette.backgroundColors(for: scheme), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Abstract circles background
            Circle()
                .fill(Color.pink.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 120, y: 150)

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear { isAnimating = true }

                    Text("Unlock Everything")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Get full access to all 59 Kama Sutra positions, spicy challenges, and unlimited fun.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 24)
                }
                .padding(.top, 40)

                // Features
                VStack(spacing: 16) {
                    FeatureRow(icon: "lock.open.fill", text: "Unlock all 59 Positions")
                    FeatureRow(icon: "flame.circle.fill", text: "Access 'Extra Hot' Challenges")
                    FeatureRow(icon: "trash.fill", text: "Unlock 'Erase All' Feature") // Added explicit mention
                    FeatureRow(icon: "star.fill", text: "Ad-free Experience")
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal)

                Spacer()

                // Products
                if store.products.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Loading products...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("If nothing appears, ensure you have set up In-App Purchases in App Store Connect or a local StoreKit Configuration file.")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                    }
                    .frame(height: 140)
                    .task {
                        await store.requestProducts()
                    }
                } else {
                    VStack(spacing: 12) {
                        if !isAuthed {
                            VStack(spacing: 6) {
                                Text("Optional: Sign in to save your premium across devices.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.75))
                                Button {
                                    showAuthSheet = true
                                } label: {
                                    Text("Sign In / Create Account")
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        ForEach(store.products, id: \.id) { product in
                            Button(action: {
                                Task {
                                    Haptics.selection()
                                    do {
                                        _ = try await store.purchase(product)
                                    } catch {
                                        print("Purchase failed: \(error)")
                                    }
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.displayName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        // Specific badge for Lifetime/Premium
                                        if product.id.contains("lifetime") {
                                            Text("BEST VALUE • UNLOCKS ERASE ALL")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.yellow)
                                                .padding(.top, 2)
                                        } else {
                                            Text(product.description)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.white.opacity(0.15)))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(product.id.contains("lifetime") ? LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: product.id.contains("lifetime") ? 3 : 2)
                                )
                                .background(Color("cardBg1").opacity(0.5))
                                .cornerRadius(14)
                                .shadow(color: product.id.contains("lifetime") ? Color.orange.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }

                Button(action: {
                    Haptics.selection()
                    dismiss()
                }) {
                    Text("Maybe Later")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                        .padding()
                }
            }
            .padding(.bottom)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationView {
                // On success, dismiss sheet; purchase can be re-triggered by user
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.pink)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}
