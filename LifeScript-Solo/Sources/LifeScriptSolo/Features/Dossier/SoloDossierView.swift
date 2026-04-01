import SwiftUI

struct SoloDossierView: View {
    let book: Book
    let relationships: [RelationshipState]
    let snapshot: SoloDossierSnapshot
    private let branding = SoloStoryConfig.branding
    @State private var focusedIndex = 0
    @State private var showDestinySheet = false

    var body: some View {
        ZStack {
            SoloBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    SoloCharacterCarousel(entries: carouselEntries, focusedIndex: $focusedIndex)
                        .padding(.top, 8)

                    if let entry = focusedEntry {
                        SoloCharacterSheet(entry: entry, destinyStatus: snapshot.destinyStatus)
                            .id(entry.id)
                            .transition(.opacity.combined(with: .offset(y: 12)))
                    } else {
                        Text(SoloLocalization.localized("暂无可展示角色。"))
                            .font(SoloTypography.detail)
                            .foregroundStyle(SoloTheme.muted)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .soloPanel(.stage, prominence: 0.12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
        }
        .soloStoryChrome(title: branding.dossierTitle, kicker: SoloLocalization.localized("档案"))
        .safeAreaInset(edge: .top) {
            SoloDestinyStrip(snapshot: snapshot) {
                showDestinySheet = true
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(Color.black.opacity(0.10))
        }
        .sheet(isPresented: $showDestinySheet) {
            NavigationStack {
                ScrollView {
                    SoloDestinyIntelPanel(snapshot: snapshot)
                        .padding(20)
                }
                .navigationTitle(SoloLocalization.localized("天机情报"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(SoloLocalization.localized("完成")) { showDestinySheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            focusedIndex = defaultFocusedIndex
        }
    }

    private var relationByID: [String: RelationshipState] {
        Dictionary(uniqueKeysWithValues: relationships.map { ($0.characterId, $0) })
    }

    private var carouselEntries: [SoloCarouselEntry] {
        book.characters.map { character in
            let relation = relationByID[character.id]
            return SoloCarouselEntry(
                character: character,
                relation: relation,
                intel: SoloCharacterIntel.build(character: character, relation: relation)
            )
        }
    }

    private var focusedEntry: SoloCarouselEntry? {
        guard !carouselEntries.isEmpty else { return nil }
        let safeIndex = min(max(focusedIndex, 0), carouselEntries.count - 1)
        return carouselEntries[safeIndex]
    }

    private var defaultFocusedIndex: Int {
        guard !carouselEntries.isEmpty else { return 0 }
        let maxItem = carouselEntries.enumerated().max { lhs, rhs in
            lhs.element.intel.influence < rhs.element.intel.influence
        }
        return maxItem?.offset ?? 0
    }
}
