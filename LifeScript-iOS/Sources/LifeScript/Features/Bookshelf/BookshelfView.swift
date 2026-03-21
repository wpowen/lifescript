import SwiftUI
import SwiftData

struct BookshelfView: View {
    @Query(sort: \ReadingProgress.lastReadDate, order: .reverse)
    private var progressList: [ReadingProgress]

    @State private var allBooks: [Book] = []
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Group {
            if readingBooks.isEmpty {
                EmptyStateView(
                    symbol: "books.vertical",
                    title: "书架空空如也",
                    subtitle: "去发现页找一本好书开始你的命运之旅吧",
                    action: { coordinator.selectTab(.home) },
                    actionTitle: "去发现"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: .spacing12) {
                        ForEach(readingBooks) { bookProgress in
                            if let book = allBooks.first(where: { $0.id == bookProgress.bookId }) {
                                BookshelfCard(book: book, progress: bookProgress) {
                                    coordinator.navigate(to: .reading(book, bookProgress.currentChapterId))
                                }
                                .onTapGesture {
                                    coordinator.navigate(to: .reading(book, bookProgress.currentChapterId))
                                }
                            }
                        }
                    }
                    .padding(.spacing16)
                }
            }
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("书架")
        .task { await loadBooks() }
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

    var body: some View {
        HStack(spacing: .spacing12) {
            RoundedRectangle(cornerRadius: .radiusSmall)
                .fill(Color.surfaceHighlight)
                .frame(width: 60, height: 80)
                .overlay(
                    Text(String(book.title.prefix(1)))
                        .font(.titleLarge)
                        .foregroundStyle(Color.accentGold.opacity(0.6))
                )

            VStack(alignment: .leading, spacing: .spacing4) {
                Text(book.title)
                    .font(.labelLarge)
                    .foregroundStyle(Color.textPrimary)

                Text("已读 \(progress.completedChapterIds.count)/\(book.totalChapters) 章")
                    .font(.captionLarge)
                    .foregroundStyle(Color.textSecondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.surfaceSecondary)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentGold)
                            .frame(width: geo.size.width * progressRatio)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            Button("继续") { onContinue?() }
                .buttonStyle(.secondary)
        }
        .padding(.spacing12)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMedium))
    }

    private var progressRatio: Double {
        guard book.totalChapters > 0 else { return 0 }
        return Double(progress.completedChapterIds.count) / Double(book.totalChapters)
    }
}
