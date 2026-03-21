import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .loaded(let books):
                contentView(books: books)
            case .error(let message):
                errorView(message: message)
            }
        }
        .background(Color.backgroundPrimary)
        .task { await viewModel.onAppear() }
    }

    // MARK: - Content

    private func contentView(books: [Book]) -> some View {
        ScrollView {
            VStack(spacing: .spacing24) {
                headerView
                featuredSection
                genreSection
                allBooksSection(books: books)
            }
            .padding(.bottom, .spacing32)
        }
        .refreshable { await viewModel.onRefresh() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacing4) {
                Text("命书")
                    .font(.displayLarge)
                    .foregroundStyle(Color.textPrimary)
                Text("你来改命")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Button {
                coordinator.selectTab(.profile)
            } label: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, .spacing16)
        .padding(.top, .spacing16)
    }

    // MARK: - Featured

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            sectionHeader("今日推荐")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    ForEach(viewModel.featuredBooks) { book in
                        FeaturedBookCard(book: book)
                            .onTapGesture {
                                coordinator.navigate(to: .bookDetail(book))
                            }
                    }
                }
                .padding(.horizontal, .spacing16)
            }
        }
    }

    // MARK: - Genre

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            sectionHeader("题材分类")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing12) {
                    ForEach(Book.Genre.allCases, id: \.self) { genre in
                        GenreCard(genre: genre)
                    }
                }
                .padding(.horizontal, .spacing16)
            }
        }
    }

    // MARK: - All Books

    private func allBooksSection(books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            sectionHeader("全部作品")
            LazyVStack(spacing: .spacing12) {
                ForEach(books) { book in
                    BookListCard(book: book)
                        .onTapGesture {
                            coordinator.navigate(to: .bookDetail(book))
                        }
                }
            }
            .padding(.horizontal, .spacing16)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.titleMedium)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, .spacing16)
    }

    private var loadingView: some View {
        ProgressView()
            .tint(Color.accentGold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundPrimary)
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            symbol: "exclamationmark.triangle",
            title: "加载失败",
            subtitle: message,
            action: { Task { await viewModel.onRefresh() } },
            actionTitle: "重试"
        )
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Featured Book Card

struct FeaturedBookCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing8) {
            // Cover with rich gradient and title overlay
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: .radiusMedium)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentGold.opacity(0.25),
                                Color.accentCrimson.opacity(0.15),
                                Color.surfacePrimary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 140)
                    .overlay(
                        // Decorative character watermark
                        Text(String(book.title.prefix(1)))
                            .font(.system(size: 80, weight: .bold, design: .serif))
                            .foregroundStyle(Color.accentGold.opacity(0.08))
                            .offset(x: 40, y: -10)
                    )

                // Bottom gradient for text readability
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: .radiusMedium,
                        bottomTrailingRadius: .radiusMedium
                    )
                )

                VStack(alignment: .leading, spacing: .spacing2) {
                    Text(book.title)
                        .font(.titleMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text(book.author)
                        .font(.captionSmall)
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.spacing12)
            }
            .frame(width: 200, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))

            TagFlowView(tags: Array(book.tags.prefix(3)))
        }
        .frame(width: 200)
    }
}

// MARK: - Genre Card

struct GenreCard: View {
    let genre: Book.Genre

    var body: some View {
        VStack(spacing: .spacing8) {
            Image(systemName: genre.iconName)
                .font(.system(size: 24))
                .foregroundStyle(Color.accentGold)
            Text(genre.displayName)
                .font(.labelSmall)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(width: 80, height: 80)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }
}

// MARK: - Book List Card

struct BookListCard: View {
    let book: Book

    var body: some View {
        HStack(spacing: .spacing12) {
            // Book cover
            RoundedRectangle(cornerRadius: .radiusSmall)
                .fill(
                    LinearGradient(
                        colors: [Color.accentGold.opacity(0.2), Color.surfaceHighlight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 95)
                .overlay(
                    VStack(spacing: .spacing4) {
                        Text(String(book.title.prefix(1)))
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color.accentGold.opacity(0.7))
                        Rectangle()
                            .fill(Color.accentGold.opacity(0.3))
                            .frame(width: 24, height: 1)
                    }
                )

            VStack(alignment: .leading, spacing: .spacing6) {
                Text(book.title)
                    .font(.labelLarge)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(book.synopsis)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)

                TagFlowView(tags: Array(book.tags.prefix(4)))

                HStack(spacing: .spacing8) {
                    Label("\(book.totalChapters)章", systemImage: "book")
                    Label(book.genre.displayName, systemImage: genre.iconName)
                }
                .font(.captionLarge)
                .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.spacing12)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }

    private var genre: Book.Genre { book.genre }
}
