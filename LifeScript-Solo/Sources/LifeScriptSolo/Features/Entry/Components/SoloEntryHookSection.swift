import SwiftUI

struct SoloEntryHookSection: View {
    let snapshot: SoloEntrySnapshot
    let primaryActionTitle: String
    let secondaryActionTitle: String
    let readingRoute: SoloRoute?
    let openWorld: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SoloEntrySectionHeader(
                eyebrow: SoloLocalization.localized("再往前一步"),
                title: snapshot.branding.landing.hookTitle,
                detail: snapshot.branding.landing.hookBody
            )

            Text(snapshot.hookLine)
                .font(SoloTypography.sceneHeadline(size: 24))
                .foregroundStyle(SoloTheme.ink)
                .lineSpacing(6)

            HStack(spacing: 10) {
                SoloSignalChip(text: snapshot.currentIdentityValue, tint: SoloTheme.gold)
                if let hiddenRouteHint = snapshot.hiddenRouteHint {
                    SoloSignalChip(text: hiddenRouteHint, tint: SoloTheme.crimson)
                }
            }

            VStack(spacing: 12) {
                if let readingRoute {
                    NavigationLink(value: readingRoute) {
                        HStack {
                            Text(primaryActionTitle)
                                .font(SoloTypography.label)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                    }
                    .buttonStyle(SoloPrimaryActionButtonStyle())
                } else {
                    HStack {
                        Text(SoloLocalization.localized("章节装载中"))
                            .font(SoloTypography.label)
                        Spacer()
                        Image(systemName: "hourglass")
                            .font(.title3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .foregroundStyle(Color.black.opacity(0.65))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.75))
                    )
                }

                Button(action: openWorld) {
                    HStack {
                        Text(secondaryActionTitle)
                        Spacer()
                        Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    }
                    .font(SoloTypography.label)
                    .foregroundStyle(SoloTheme.ink)
                }
                .buttonStyle(SoloEntrySecondaryButtonStyle())
            }
        }
        .padding(24)
        .soloPanel(.alert, prominence: 0.22)
    }
}
