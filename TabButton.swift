import SwiftUI

struct TabButton: View {
    let icon: String
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selected ? .white : .gray.opacity(0.6))

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
                    } else {
                        Color.clear
                    }
                }
            )
        }
    }
}

