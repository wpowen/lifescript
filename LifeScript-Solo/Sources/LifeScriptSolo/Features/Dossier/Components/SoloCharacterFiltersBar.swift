import SwiftUI

enum SoloCharacterFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case pullable = "可牵引"
    case highRisk = "高风险"
    case pivotal = "高局重"

    var id: String { rawValue }
}

struct SoloCharacterFiltersBar: View {
    @Binding var selected: SoloCharacterFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SoloCharacterFilter.allCases) { filter in
                    Button {
                        selected = filter
                    } label: {
                        Text(SoloLocalization.localized(filter.rawValue))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selected == filter ? SoloTheme.ink : SoloTheme.muted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(selected == filter ? SoloTheme.gold.opacity(0.28) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

