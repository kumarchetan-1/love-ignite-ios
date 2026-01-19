import SwiftUI

struct FilterTabs: View {
    @Binding var selectedTab: PosterGridView.FilterTab
    @AppStorage("hide_explicit") private var hideExplicit: Bool = true
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(visibleTabs) { tab in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(textColor(for: tab))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(backgroundColor(for: tab))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor(for: tab), lineWidth: 1)
                            )
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .onChange(of: hideExplicit) { newValue in
            if newValue && selectedTab == .kama {
                selectedTab = .all
            }
        }
    }
    
    private var visibleTabs: [PosterGridView.FilterTab] {
        if hideExplicit {
            return [.all, .qna, .indoor, .outdoor]
        } else {
            return [.all, .qna, .indoor, .outdoor, .kama]
        }
    }
    
    private func textColor(for tab: PosterGridView.FilterTab) -> Color {
        if selectedTab == tab {
            return .white
        } else {
            return scheme == .dark ? .white.opacity(0.7) : Color.pink.opacity(0.8)
        }
    }
    
    private func backgroundColor(for tab: PosterGridView.FilterTab) -> Color {
        if selectedTab == tab {
            return Color.pink.opacity(0.9)
        } else {
            return scheme == .dark ? Color.white.opacity(0.08) : Color.pink.opacity(0.06)
        }
    }
    
    private func borderColor(for tab: PosterGridView.FilterTab) -> Color {
        if selectedTab == tab {
            return .clear
        } else {
            return scheme == .dark ? .clear : Color.pink.opacity(0.1)
        }
    }
}
