import SwiftUI

struct StatBar: View {
    let label: String
    let value: Int
    let maxValue: Int
    let color: Color
    var change: Int = 0

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(Double(value) / Double(maxValue), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            HStack {
                Text(label)
                    .font(.labelSmall)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                HStack(spacing: .spacing4) {
                    Text("\(value)")
                        .font(.labelMedium)
                        .foregroundStyle(Color.textPrimary)
                    if change != 0 {
                        Text(change > 0 ? "+\(change)" : "\(change)")
                            .font(.captionLarge)
                            .foregroundStyle(change > 0 ? Color.success : Color.error)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceSecondary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color
    var change: Int = 0

    var body: some View {
        VStack(spacing: .spacing4) {
            Text("\(value)")
                .font(.statValue)
                .foregroundStyle(color)
            Text(label)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
            if change != 0 {
                Text(change > 0 ? "+\(change)" : "\(change)")
                    .font(.captionSmall)
                    .foregroundStyle(change > 0 ? Color.success : Color.error)
                    .padding(.horizontal, .spacing6)
                    .padding(.vertical, .spacing2)
                    .background(
                        Capsule()
                            .fill(change > 0 ? Color.success.opacity(0.15) : Color.error.opacity(0.15))
                    )
            }
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    VStack(spacing: 16) {
        StatBar(label: "战力", value: 35, maxValue: 100, color: .statCombat, change: 5)
        StatBar(label: "名望", value: 20, maxValue: 100, color: .statFame)
        StatBadge(label: "战力", value: 35, color: .statCombat, change: 5)
    }
    .padding()
    .background(Color.backgroundPrimary)
}
