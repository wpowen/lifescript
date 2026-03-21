import SwiftUI
import SwiftData

struct BookshelfView: View {
    @Query(sort: \ReadingProgress.lastReadDate, order: .reverse)
    private var progressList: [ReadingProgress]

    @State private var allBooks: [Book] = []
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            SceneBackdrop(palette: StoryPalette(primary: .accentSky, secondary: .accentGold, tertiary: .accentEmerald))

            Group {
                if readingBooks.isEmpty {
                    EmptyStateView(
                        symbol: "books.vertical",
                        title: "还没有正在推进的故事",
                        subtitle: "去故事页挑一段命运，开始你的第一场操盘。",
                        action: { coordinator.selectTab(.home) },
                        actionTitle: "去选故事"
                    )
                } else {
                    contentView
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.backgroundPrimary, for: .navigationBar)
        .task { await loadBooks() }
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing24) {
                ScenePageHeader(
                    eyebrow: "在读档案",
                    title: "你的故事还在继续",
                    subtitle: "这里不是简单书架，而是你已经落子过、会继续回来的剧情现场。",
                    accent: .accentSky
                )

                summaryStrip

                LazyVStack(spacing: .spacing16) {
                    ForEach(readingBooks) { bookProgress in
                        if let book = allBooks.first(where: { $0.id == bookProgress.bookId }) {
                            BookshelfCard(book: book, progress: bookProgress) {
                                coordinator.navigate(to: .reading(book, bookProgress.currentChapterId))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, .spacing16)
            .padding(.top, .spacing20)
            .padding(.bottom, .spacing40)
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: .spacing10) {
            SceneMetricPill(
                title: "在读故事",
                value: "\(readingBooks.count) 本",
                systemImage: "bookmark.fill",
                color: .accentSky
            )
            SceneMetricPill(
                title: "已读章节",
                value: "\(readingBooks.reduce(0) { $0 + $1.completedChapterIds.count }) 章",
                systemImage: "text.book.closed.fill",
                color: .accentGold
            )
            SceneMetricPill(
                title: "最近动作",
                value: "继续推进",
                systemImage: "arrow.trianglehead.clockwise",
                color: .accentEmerald
            )
        }
    }

    private var readingBooks: [ReadingProgress] {
        progressList
    }

    private func loadBooks() async {
        do {
            allBooks = try await BundledContentLoader().listBooks()
        } catch {
            allBooks = []
        }
    }
}

struct BookshelfCard: View {
    let book: Book
    let progress: ReadingProgress
    var onContinue: (() -> Void)?

    private var progressRatio: Double {
        guard book.totalChapters > 0 else { return 0 }
        return Double(progress.completedChapterIds.count) / Double(book.totalChapters)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            HStack(alignment: .top, spacing: .spacing16) {
                RoundedRectangle(cornerRadius: .radiusMedium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                book.palette.primary.opacity(0.26),
                                book.palette.secondary.opacity(0.18),
                                Color.surfaceSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 86, height: 120)
                    .overlay(
                        Text(String(book.title.prefix(1)))
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(book.palette.primary)
                    )

                VStack(alignment: .leading, spacing: .spacing8) {
                    HStack {
                        Text(book.title)
                            .font(.titleSmall)
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        SceneAccentBadge(text: "继续中", color: book.palette.secondary)
                    }

                    Text(book.sceneSummary)
                        .font(.captionLarge)
                        .foregroundStyle(book.palette.primary)

                    Text("已读 \(progress.completedChapterIds.count)/\(book.totalChapters) 章")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)

                    Text("上次读到的剧情入口已为你保留。")
                        .font(.captionLarge)
                        .foregroundStyle(Color.textTertiary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.surfaceSecondary)
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [book.palette.primary, book.palette.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressRatio)
                }
            }
            .frame(height: 10)

            Button {
                onContinue?()
            } label: {
                SceneCTAButtonLabel(
                    title: "继续当前剧情",
                    subtitle: "直接回到你的上次落点",
                    systemImage: "play.fill"
                )
            }
            .buttonStyle(.primary)
        }
        .scenePanel(accent: book.palette.primary, padding: .spacing18)
    }
}
