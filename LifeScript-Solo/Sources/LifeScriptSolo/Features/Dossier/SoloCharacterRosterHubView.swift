import SwiftUI

struct SoloCharacterRosterHubView: View {
    let book: Book
    let relationships: [RelationshipState]
    let snapshot: SoloDossierSnapshot

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedFilter: SoloCharacterFilter = .all

    private var layout: SoloCharacterResponsiveLayout {
        SoloCharacterResponsiveLayout(horizontalSizeClass: horizontalSizeClass)
    }

    private var relationByID: [String: RelationshipState] {
        Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })
    }

    private var roster: [(character: Character, relation: RelationshipState?, intel: SoloCharacterIntel)] {
        book.characters.map { character in
            let relation = relationByID[character.id]
            let intel = SoloCharacterIntel.build(character: character, relation: relation)
            return (character, relation, intel)
        }
        .sorted { lhs, rhs in
            if lhs.intel.influence == rhs.intel.influence {
                return lhs.character.name < rhs.character.name
            }
            return lhs.intel.influence > rhs.intel.influence
        }
    }

    private var filteredRoster: [(character: Character, relation: RelationshipState?, intel: SoloCharacterIntel)] {
        roster.filter { item in
            switch selectedFilter {
            case .all:
                return true
            case .pullable:
                return item.intel.recommendedTag == .pullable
            case .highRisk:
                return item.intel.recommendedTag == .highRisk
            case .pivotal:
                return item.intel.recommendedTag == .pivotal
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerPanel
            SoloCharacterFiltersBar(selected: $selectedFilter)

            if layout.usesSidebarColumn {
                HStack(alignment: .top, spacing: 14) {
                    rosterGrid
                    destinySidebar
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    destinySidebar
                    rosterGrid
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SoloLocalization.localized("人物战局总览"))
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)
            Text(SoloLocalization.localized("先看谁最重要、谁最危险、谁最适合牵引，再决定进入哪位角色的战局面板。"))
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)
        }
        .padding(20)
        .soloPanel(.hero, prominence: 0.2)
    }

    private var rosterGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: layout.rosterColumnCount
        )

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredRoster, id: \.character.id) { item in
                NavigationLink {
                    SoloCharacterBattlePanelView(
                        character: item.character,
                        relation: item.relation,
                        destinyStatus: snapshot.destinyStatus
                    )
                } label: {
                    SoloCharacterBattleCard(
                        character: item.character,
                        relation: item.relation,
                        intel: item.intel
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var destinySidebar: some View {
        if let width = layout.sidebarWidth {
            SoloDestinyIntelPanel(snapshot: snapshot)
                .frame(width: width)
        } else {
            SoloDestinyIntelPanel(snapshot: snapshot)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

