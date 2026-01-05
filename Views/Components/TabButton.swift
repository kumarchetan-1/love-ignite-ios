import SwiftUI

struct TabButton: View {
    let icon: String
    let title: String
    let selected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: {
            if !selected {
            Haptics.selection()
                action()
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if selected {
                        Capsule()
                            .fill(activeColor.opacity(scheme == .dark ? 0.15 : 0.12))
                            .matchedGeometryEffect(id: "TabBackground", in: namespace)
                            .frame(width: 44, height: 30)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(scheme == .dark ? 0.2 : 0.5), lineWidth: 0.5)
                            )
                    }
                    
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selected ? activeColor : inactiveColor)
                }
                .frame(height: 30)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(selected ? activeColor : inactiveColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var activeColor: Color {
        scheme == .light ? .pink : .white
    }
    
    private var inactiveColor: Color {
        scheme == .light ? Color.black.opacity(0.35) : .white.opacity(0.35)
    }
}
