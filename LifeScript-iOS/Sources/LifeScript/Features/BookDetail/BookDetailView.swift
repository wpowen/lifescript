import SwiftUI

struct BookDetailView: View {
    @State private var viewModel: BookDetailViewModel
    @Environment(AppCoordinator.self) private var coordinator

    init(book: Book) {
        _viewModel = State(initialValue: BookDetailViewModel(book: book))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacing24) {
                heroSection
                tagsSection
                synopsisSection
                charactersSection
                chapterListSection
            }
            .padding(.bottom, .spacing32)
        }
        .background(Color.backgroundPrimary)
        .overlay(alignment: .bottom) { startReadingButton }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .task { await viewModel.onAppear() }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Cover gradient
            LinearGradient(
                colors: [Color.accentGold.opacity(0.15), Color.backgroundPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            VStack(alignment: .leading, spacing: .spacing8) {
                Text(viewModel.book.title)
                    .font(.displayLarge)
                    .foregroundStyle(Color.textPrimary)
                Text(viewModel.book.author)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                HStack(spacing: .spacing12) {
                    Label("\(viewModel.book.totalChapters)章", systemImage: "book")
                    Label(viewModel.book.genre.displayName, systemImage: viewModel.book.genre.iconName)
                    Label("高互动", systemImage: "hand.tap")
                }
                .font(.captionLarge)
                .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, .spacing16)
            .padding(.bottom, .spacing16)
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("爽点标签")
                .font(.labelMedium)
                .foregroundStyle(Color.textSecondary)
            TagFlowView(tags: viewModel.book.tags)
            if !viewModel.book.interactionTags.isEmpty {
                TagFlowView(tags: viewModel.book.interactionTags, color: .accentSky)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .spacing16)
    }

    // MARK: - Synopsis

    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            Text("简介")
                .font(.labelMedium)
                .foregroundStyle(Color.textSecondary)
            Text(viewModel.book.synopsis)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .spacing16)
    }

    // MARK: - Characters Preview

    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("主要角色")
                .font(.labelMedium)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, .spacing16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    ForEach(viewModel.book.characters) { character in
                        CharacterPreviewCard(character: character)
                    }
                }
                .padding(.horizontal, .spacing16)
            }
        }
    }

    // MARK: - Chapter List

    private var chapterListSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            Text("章节目录")
                .font(.labelMedium)
                .foregroundStyle(Color.textSecondary)

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.accentGold)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.chapters) { chapter in
                    ChapterRow(chapter: chapter)
                }
            }
        }
        .padding(.horizontal, .spacing16)
        .padding(.bottom, 80) // Space for floating button
    }

    // MARK: - Start Reading Button

    private var startReadingButton: some View {
        Button {
            if let chapterId = viewModel.firstChapterId {
                coordinator.navigate(to: .reading(viewModel.book, chapterId))
            }
        } label: {
            Text("开始阅读")
        }
        .buttonStyle(.primary)
        .padding(.horizontal, .spacing16)
        .padding(.bottom, .spacing16)
        .background(
            LinearGradient(
                colors: [Color.backgroundPrimary.opacity(0), Color.backgroundPrimary],
                startPoint: .top,
                endPoint: .center
            )
        )
    }
}

// MARK: - Character Preview Card

struct CharacterPreviewCard: View {
    let character: Character

    var body: some View {
        VStack(spacing: .spacing8) {
            Circle()
                .fill(Color.surfaceHighlight)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(character.name.prefix(1)))
                        .font(.titleMedium)
                        .foregroundStyle(Color.accentGold)
                )
            Text(character.name)
                .font(.labelSmall)
                .foregroundStyle(Color.textPrimary)
            Text(character.role.rawValue)
                .font(.captionSmall)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(width: 80)
    }
}

// MARK: - Chapter Row

struct ChapterRow: View {
    let chapter: Chapter

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing4) {
                Text("第\(chapter.number)章")
                    .font(.chapterNumber)
                    .foregroundStyle(Color.textTertiary)
                Text(chapter.title)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            if chapter.isPaid {
                Image(systemName: "lock.fill")
                    .font(.captionLarge)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, .spacing8)
    }
}
