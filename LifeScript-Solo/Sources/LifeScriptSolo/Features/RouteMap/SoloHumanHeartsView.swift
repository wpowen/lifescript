import SwiftUI

struct SoloHumanHeartsView: View {
    let book: Book
    let relationships: [RelationshipState]
    let snapshot: SoloHumanHeartsSnapshot
    let destinyStatus: SoloDestinyStatus

    private var relationByID: [String: RelationshipState] {
        Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })
    }

    var body: some View {
        ZStack {
            sceneBackground
            contentDimmer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerPanel
                    ForEach(snapshot.rings) { ring in
                        ringPanel(ring)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: book.id == "天机录" ? "人心" : "人物", kicker: "观心")
    }

    @ViewBuilder
    private var sceneBackground: some View {
        if book.id == "天机录" {
            TianjiluHomeScene(illustration: TianjiluArtworkCatalog.dossierBackdrop)
                .ignoresSafeArea()
        } else {
            SoloBackdrop()
        }
    }

    private var contentDimmer: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.50),
                Color.black.opacity(0.78),
                Color.black.opacity(0.92),
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.38)
        )
        .ignoresSafeArea()
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("人心盘")
                .font(SoloTypography.posterTitle(size: 30))
                .foregroundStyle(SoloTheme.ink)

            if book.id == "天机录" {
                SoloArtworkCard(
                    asset: TianjiluArtworkCatalog.dossierBackdrop,
                    height: 168,
                    contentMode: .fill,
                    tint: SoloTheme.gold,
                    cornerRadius: 18
                )
            }

            Text(snapshot.spotlightLine)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.warmInk)
                .lineSpacing(5)
            Text(snapshot.pressureLine)
                .font(SoloTypography.detail)
                .foregroundStyle(SoloTheme.muted)
                .lineSpacing(5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    badge(text: "天命：\(destinyStatus.headline)", tint: destinyTint)
                    ForEach(snapshot.rings) { ring in
                        badge(text: "\(ring.title) \(ring.characterIDs.count)", tint: ringTint(for: ring))
                    }
                }
            }
        }
        .padding(20)
        .soloPanel(.hero, prominence: 0.16)
    }

    @ViewBuilder
    private func ringPanel(_ ring: SoloHeartRing) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(ring.title)
                        .font(SoloTypography.sectionTitle())
                        .foregroundStyle(SoloTheme.ink)
                    Text(ring.subtitle)
                        .font(SoloTypography.detail)
                        .foregroundStyle(SoloTheme.muted)
                        .lineSpacing(5)
                }
                Spacer()
                badge(text: "\(ring.characterIDs.count) 人", tint: ringTint(for: ring))
            }

            if ring.characterIDs.isEmpty {
                Text("暂无可显示角色。")
                    .font(SoloTypography.detail)
                    .foregroundStyle(SoloTheme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(ring.characterIDs, id: \.self) { characterID in
                            if let character = book.characters.first(where: { $0.id == characterID }) {
                                let relation = relationByID[characterID]
                                NavigationLink {
                                    SoloCharacterSheetSceneView(
                                        entry: SoloCarouselEntry(
                                            character: character,
                                            relation: relation,
                                            intel: SoloCharacterIntel.build(character: character, relation: relation)
                                        ),
                                        destinyStatus: destinyStatus
                                    )
                                } label: {
                                    SoloCharacterBattleCard(
                                        character: character,
                                        relation: relation,
                                        intel: SoloCharacterIntel.build(character: character, relation: relation)
                                    )
                                    .frame(width: 244)
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(20)
        .soloPanel(.stage, prominence: 0.12)
    }

    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.12)))
    }

    private var destinyTint: Color {
        switch destinyStatus.level {
        case .abundant:
            return SoloTheme.jade
        case .steady:
            return SoloTheme.gold
        case .strained, .critical:
            return SoloTheme.crimson
        }
    }

    private func ringTint(for ring: SoloHeartRing) -> Color {
        switch ring.id {
        case "in-play":
            return SoloTheme.jade
        case "testable":
            return SoloTheme.gold
        case "dangerous":
            return SoloTheme.crimson
        default:
            return SoloTheme.muted
        }
    }
}
