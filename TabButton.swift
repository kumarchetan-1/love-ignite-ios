import SwiftUI

struct TabButton: View {
    let icon: String
    let title: String
    let selected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

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
                    .foregroundColor(selected ? .white : .gray.opacity(0.6))
                    .scaleEffect(selected ? 1.1 : 1.0)

                Text(title)
                    .font(.caption)
                    .foregroundColor(selected ? .white : .gray.opacity(0.6))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if selected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.12))
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
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

