import SwiftUI

struct TagView: View {
    let text: String
    var color: Color = .accentGold

    var body: some View {
        Text(text)
            .font(.captionLarge)
            .foregroundStyle(color)
            .padding(.horizontal, .spacing8)
            .padding(.vertical, .spacing4)
            .background(
                RoundedRectangle(cornerRadius: .radiusSmall)
                    .fill(color.opacity(0.15))
            )
    }
}

struct TagFlowView: View {
    let tags: [String]
    var color: Color = .accentGold

    var body: some View {
        FlowLayout(spacing: .spacing6) {
            ForEach(tags, id: \.self) { tag in
                TagView(text: tag, color: color)
            }
        }
    }
}

// MARK: - Flow Layout (horizontal wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    TagFlowView(tags: ["打脸逆袭", "高智商布局", "修罗场", "轻养成", "扮猪吃虎"])
        .padding()
        .background(Color.backgroundPrimary)
}
