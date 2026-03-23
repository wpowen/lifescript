import SwiftUI

private struct SoloStoryChromeTitle: View {
    let kicker: String?
    let title: String

    var body: some View {
        VStack(spacing: 2) {
            if let kicker {
                Text(kicker.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(SoloTheme.gold.opacity(0.88))
            }

            Text(title)
                .font(SoloTypography.chromeTitle())
                .foregroundStyle(SoloTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct SoloChromeIconButton: View {
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func soloStoryChrome(title: String, kicker: String? = nil) -> some View {
        toolbar {
            ToolbarItem(placement: .principal) {
                SoloStoryChromeTitle(kicker: kicker, title: title)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
