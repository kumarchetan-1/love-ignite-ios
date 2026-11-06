import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Last Updated: January 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SectionView(title: "1. Acceptance of Terms", content: "By accessing or using Love Ignite, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.")
                    
                    SectionView(title: "2. User Accounts", content: "You are responsible for maintaining the confidentiality of your account and password. You agree to provide accurate and complete information when creating an account.")
                    
                    SectionView(title: "3. Privacy Policy", content: "Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using Love Ignite, you consent to our collection and use of data as outlined in our Privacy Policy.")
                    
                    SectionView(title: "4. Content & Conduct", content: "Users are responsible for the content they unlock or sync. You agree not to use the app for any illegal or unauthorized purpose.")
                    
                    SectionView(title: "5. Pricing", content: "Love Ignite is free to use. There are no in-app purchases or subscriptions.")
                    
                    SectionView(title: "6. Limitation of Liability", content: "Love Ignite is provided 'as is' without warranties of any kind. We are not liable for any damages arising from your use of the application.")
                    
                    SectionView(title: "7. Contact Us", content: "If you have any questions regarding these Terms, please contact us at kumarchetan.npr@gmail.com")
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TermsOfServiceView()
}

