import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String
    var action: (() -> Void)?
    var actionTitle: String = "开始"

    var body: some View {
        VStack(spacing: .spacing16) {
            Image(systemName: symbol)
                .font(.system(size: 56))
                .foregroundStyle(Color.accentGold)
            Text(title)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)
            Text(subtitle)
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.top, .spacing8)
            }
        }
        .scenePanel(accent: .accentGold, padding: .spacing32)
        .padding(.spacing16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
