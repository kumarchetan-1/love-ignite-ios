import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Last Updated: January 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    SectionView(title: "1. Information We Collect", content: "We collect information you provide directly to us, such as your name and email address when you create an account. We also collect data related to your progress in the app, including unlocked cards and achievements, to provide cloud sync features.")
                    
                    SectionView(title: "2. How We Use Information", content: "We use the information we collect to maintain your account, sync your progress across devices, communicate with you about your account (e.g., verification codes), and improve our services.")
                    
                    SectionView(title: "3. Data Sharing", content: "We do not sell your personal information. We may share data with trusted third-party services necessary for app functionality: Google (for authentication), Brevo (for transactional emails), and Apple (for in-app purchases).")
                    
                    SectionView(title: "4. Data Security", content: "We implement industry-standard security measures to protect your data. Your password is encrypted before being stored on our servers.")
                    
                    SectionView(title: "5. Your Rights", content: "You have the right to access, correct, or delete your personal information. You can update your profile or delete your account directly within the app settings.")
                    
                    SectionView(title: "6. Children's Privacy", content: "Love Ignite is not intended for children under the age of 18. We do not knowingly collect personal information from children.")
                    
                    SectionView(title: "7. Contact Us", content: "If you have any questions about this Privacy Policy, please contact us at kumarchetan.npr@gmail.com")
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
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

#Preview {
    PrivacyPolicyView()
}

