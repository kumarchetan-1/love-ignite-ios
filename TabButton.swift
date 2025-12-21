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
            Haptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selected ? activeColor : inactiveColor)
                    .scaleEffect(selected ? 1.1 : 1.0)

                Text(title)
                    .font(.caption)
                    .foregroundColor(selected ? activeColor : inactiveColor)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if selected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedBackground)
                            .matchedGeometryEffect(id: "TabBackground", in: namespace)
                    } else {
                        Color.clear
                    }
                }
            )
            .scaleEffect(selected ? 1.05 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var activeColor: Color {
        scheme == .light ? Color.black : .white
    }
    
    private var inactiveColor: Color {
        scheme == .light ? Color.black.opacity(0.45) : .gray.opacity(0.6)
    }
    
    private var selectedBackground: Color {
        scheme == .light ? Color.black.opacity(0.08) : Color.white.opacity(0.12)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

