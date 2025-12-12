import SwiftUI

struct HeaderCard: View {
    let revealedCount: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(revealedCount) / Double(total), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(revealedCount)/\(total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)

            if total > 0 {
                Text("\(Int((progress * 100).rounded()))% revealed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No items yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HeaderCard(revealedCount: 7, total: 20)
        HeaderCard(revealedCount: 0, total: 0)
        HeaderCard(revealedCount: 20, total: 20)
    }
    .padding()
}
