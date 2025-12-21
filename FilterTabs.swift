import SwiftUI

struct FilterTabs: View {
    @Binding var selectedTab: PosterGridView.FilterTab
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(PosterGridView.FilterTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == tab ? Color.pink.opacity(0.9) : Color.white.opacity(0.08))
                        )
                }
            }
            Spacer()
        }
    }
}

