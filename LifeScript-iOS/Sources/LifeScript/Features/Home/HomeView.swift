import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Query(sort: \ReadingProgress.lastReadDate, order: .reverse)
    private var progressList: [ReadingProgress]

    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            SceneBackdrop(palette: featuredPalette)

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
        }
        .task { await viewModel.onAppear() }
    }

    private var featuredPalette: StoryPalette {
        heroBook?.palette
            ?? StoryPalette(primary: .accentGold, secondary: .accentCrimson, tertiary: .accentSky)
    }

    private func contentView(books: [Book]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacing24) {
                heroSection(books: books)

                if let currentStory = currentStorySnapshot(in: books) {
                    continueSection(snapshot: currentStory)
                }

                archiveSection(books: books)
                featuredSection(books: books)
                genreSection
                librarySection(books: books)
            }
            .padding(.horizontal, .spacing16)
            .padding(.top, .spacing20)
            .padding(.bottom, .spacing40)
        }
        .accessibilityIdentifier("homeRootView")
        .refreshable { await viewModel.onRefresh() }
    }

    private func heroSection(books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            ScenePageHeader(
                eyebrow: "故事大厅",
                title: "先看今晚的主舞台，再决定这一局要怎么赢",
                subtitle: "首页不是单纯书架，而是你的故事总控台。进入哪本、当前打到哪、已经攻略了什么，都要在这里一眼看懂。"
            )

            HStack(spacing: .spacing10) {
                SceneMetricPill(
                    title: "故事库",
                    value: "\(books.count) 本",
                    systemImage: "books.vertical.fill",
                    color: .accentGold
                )
                SceneMetricPill(
                    title: "在读周目",
                    value: "\(progressList.count) 条",
                    systemImage: "bookmark.fill",
                    color: .accentCrimson
                )
                SceneMetricPill(
                    title: "已攻略章节",
                    value: "\(completedChapterTotal)",
                    systemImage: "flag.pattern.checkered.2.crossed",
                    color: .accentSky
                )
            }

            if let heroBook {
                StoryLobbyHeroCard(
                    book: heroBook,
                    snapshot: currentStorySnapshot(in: books),
                    archiveCount: progressList.count,
                    completedChapterTotal: completedChapterTotal,
                    onOpen: { coordinator.navigate(to: .bookDetail(heroBook)) }
                )
            }
        }
    }

    private func continueSection(snapshot: HomeProgressSnapshot) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "在读故事档案",
                subtitle: "把当前周目的进度、已落子的次数和明确的继续入口都放在最上层。",
                accent: snapshot.book.palette.primary
            )

            CurrentCampaignDeckCard(snapshot: snapshot) {
                coordinator.navigate(to: .reading(snapshot.book, snapshot.progress.currentChapterId))
            } onOpenDetail: {
                coordinator.navigate(to: .bookDetail(snapshot.book))
            }
        }
    }

    private func archiveSection(books: [Book]) -> some View {
        let snapshots = progressSnapshots(in: books)

        return VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "攻略陈列",
                subtitle: "已经打过的故事不该消失，而是要像游戏战绩一样持续可见。",
                accent: .accentCrimson
            )

            if snapshots.isEmpty {
                ArchivePrimerCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacing16) {
                        ForEach(snapshots) { snapshot in
                            RouteArchiveCard(snapshot: snapshot) {
                                coordinator.navigate(to: .bookDetail(snapshot.book))
                            }
                        }
                    }
                    .padding(.vertical, .spacing4)
                }
            }
        }
    }

    private func featuredSection(books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "主舞台精选",
                subtitle: "用更强的视觉重心和明确动作，像精品 App 的精选主推位一样呈现作品。",
                accent: .accentGold
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacing16) {
                    ForEach(books) { book in
                        CuratedStageCard(
                            book: book,
                            snapshot: progressSnapshots(in: books).first(where: { $0.book.id == book.id })
                        ) {
                            coordinator.navigate(to: .bookDetail(book))
                        }
                    }
                }
                .padding(.vertical, .spacing4)
            }
        }
    }

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "题材剧场",
                subtitle: "题材不只是分类，而是不同的叙事空间、不同的操盘手感。",
                accent: .accentSky
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacing12) {
                ForEach(Book.Genre.allCases, id: \.self) { genre in
                    GenreMonumentCard(genre: genre)
                }
            }
        }
    }

    private func librarySection(books: [Book]) -> some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            SceneSectionHeader(
                title: "故事库",
                subtitle: "每个入口都带着清晰的玩法说明和当前状态，不让用户靠猜测进入内容。",
                accent: .accentGold
            )

            LazyVStack(spacing: .spacing16) {
                ForEach(books) { book in
                    StoryVaultCard(
                        book: book,
                        snapshot: progressSnapshots(in: books).first(where: { $0.book.id == book.id })
                    ) {
                        coordinator.navigate(to: .bookDetail(book))
                    }
                }
            }
        }
    }

    private var heroBook: Book? {
        currentStorySnapshot(in: viewModel.state.books)?.book ?? viewModel.featuredBooks.first
    }

    private func currentStorySnapshot(in books: [Book]) -> HomeProgressSnapshot? {
        guard let progress = progressList.first else { return nil }
        guard let book = books.first(where: { $0.id == progress.bookId }) else { return nil }
        return HomeProgressSnapshot(book: book, progress: progress)
    }

    private func progressSnapshots(in books: [Book]) -> [HomeProgressSnapshot] {
        progressList.compactMap { progress in
            guard let book = books.first(where: { $0.id == progress.bookId }) else { return nil }
            return HomeProgressSnapshot(book: book, progress: progress)
        }
    }

    private var completedChapterTotal: Int {
        progressList.reduce(0) { $0 + $1.completedChapterIds.count }
    }

    private var loadingView: some View {
        ProgressView()
            .tint(Color.accentGold)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            symbol: "exclamationmark.triangle",
            title: "故事大厅加载失败",
            subtitle: message,
            action: { Task { await viewModel.onRefresh() } },
            actionTitle: "重新载入"
        )
    }
}

private struct HomeProgressSnapshot: Identifiable {
    let book: Book
    let progress: ReadingProgress

    var id: String { book.id }

    var completionRatio: Double {
        guard book.totalChapters > 0 else { return 0 }
        return Double(progress.completedChapterIds.count) / Double(book.totalChapters)
    }

    var routeCount: Int {
        progress.choiceRecords?.count ?? 0
    }

    var currentChapterLabel: String {
        let digits = progress.currentChapterId.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let number = Int(digits), number > 0 {
            return "第\(number)章"
        }
        return "当前章节"
    }
}

private struct StoryLobbyHeroCard: View {
    let book: Book
    let snapshot: HomeProgressSnapshot?
    let archiveCount: Int
    let completedChapterTotal: Int
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing8) {
                    SceneAccentBadge(text: "今夜主舞台 · \(book.sceneSummary)", color: book.palette.primary)
                    Text(book.title)
                        .font(.displayMedium)
                        .foregroundStyle(Color.textPrimary)
                    Text(book.synopsis)
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(3)
                        .lineSpacing(4)
                }

                Spacer()
            }

            HStack(spacing: .spacing12) {
                LobbyStatColumn(title: "当前状态", value: snapshot?.currentChapterLabel ?? "待开启", color: book.palette.primary)
                LobbyStatColumn(title: "路线档案", value: "\(snapshot?.routeCount ?? 0) 条", color: book.palette.secondary)
                LobbyStatColumn(title: "总攻略", value: "\(completedChapterTotal) 章", color: book.palette.tertiary)
            }

            TagFlowView(tags: Array(book.tags.prefix(4)), color: book.palette.secondary)

            Button(action: onOpen) {
                SceneCTAButtonLabel(
                    title: snapshot == nil ? "进入主舞台" : "查看当前故事指挥台",
                    subtitle: snapshot == nil ? "先看详情、角色和章节入口" : "打开攻略全景、成果与继续入口",
                    systemImage: snapshot == nil ? "play.fill" : "rectangle.stack.person.crop.fill"
                )
            }
            .buttonStyle(.primary)
        }
        .padding(.spacing24)
        .background(
            RoundedRectangle(cornerRadius: .radiusXLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            book.palette.primary.opacity(0.36),
                            book.palette.secondary.opacity(0.20),
                            Color.surfaceSecondary.opacity(0.94),
                            Color.backgroundSecondary.opacity(0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusXLarge, style: .continuous)
                        .strokeBorder(book.palette.primary.opacity(0.18), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Text(String(book.title.prefix(1)))
                .font(.system(size: 150, weight: .bold, design: .serif))
                .foregroundStyle(book.palette.primary.opacity(0.10))
                .offset(x: 6, y: -10)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}

private struct LobbyStatColumn: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            Text(title)
                .font(.captionSmall)
                .foregroundStyle(Color.textTertiary)
            Text(value)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing12)
        .background(
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(Color.surfacePrimary.opacity(0.80))
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                        .strokeBorder(color.opacity(0.14), lineWidth: 1)
                )
        )
    }
}

private struct CurrentCampaignDeckCard: View {
    let snapshot: HomeProgressSnapshot
    let onContinue: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing6) {
                    Text(snapshot.book.title)
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(snapshot.currentChapterLabel) · 已推进 \(snapshot.progress.completedChapterIds.count)/\(snapshot.book.totalChapters) 章")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textSecondary)

                    Text("这本书已经进入你的在读档案，继续剧情和查看攻略都不需要再翻找入口。")
                        .font(.captionLarge)
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()

                SceneAccentBadge(text: "在读", color: snapshot.book.palette.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.surfaceSecondary)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [snapshot.book.palette.primary, snapshot.book.palette.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * snapshot.completionRatio)
                }
            }
            .frame(height: 10)

            HStack(spacing: .spacing12) {
                ProgressMetaBadge(
                    title: "已落子",
                    value: "\(snapshot.routeCount) 次",
                    color: snapshot.book.palette.primary
                )
                ProgressMetaBadge(
                    title: "最后记录",
                    value: snapshot.progress.lastReadDate.formatted(date: .abbreviated, time: .omitted),
                    color: snapshot.book.palette.tertiary
                )
            }

            HStack(spacing: .spacing12) {
                Button(action: onContinue) {
                    SceneCTAButtonLabel(
                        title: "继续当前剧情",
                        subtitle: "直接回到上次停下的位置",
                        systemImage: "arrow.forward.circle.fill"
                    )
                }
                .buttonStyle(.primary)

                Button(action: onOpenDetail) {
                    SceneCTAButtonLabel(
                        title: "查看攻略档案",
                        subtitle: "打开详情页看路线和成果",
                        systemImage: "rectangle.stack.person.crop.fill",
                        subtitleColor: Color.textSecondary
                    )
                }
                .buttonStyle(.secondary)
            }
        }
        .scenePanel(accent: snapshot.book.palette.secondary, padding: .spacing20)
    }
}

private struct ProgressMetaBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: .spacing8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)

            Text(value)
                .font(.labelMedium)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, .spacing12)
        .padding(.vertical, .spacing10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.surfaceSecondary.opacity(0.90))
        )
    }
}

private struct ArchivePrimerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .spacing10) {
            Text("还没有攻略记录")
                .font(.titleSmall)
                .foregroundStyle(Color.textPrimary)

            Text("等用户开始第一条路线后，这里会像攻略游戏的存档陈列一样，持续显示已打通章节、已落子次数和当前成果。")
                .font(.bodySmall)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(4)

            SceneAccentBadge(text: "先开启一条周目", color: .accentGold)
        }
        .scenePanel(accent: .accentGold, padding: .spacing18)
    }
}

private struct RouteArchiveCard: View {
    let snapshot: HomeProgressSnapshot
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: .spacing6) {
                    Text(snapshot.book.title)
                        .font(.titleSmall)
                        .foregroundStyle(Color.textPrimary)

                    Text(snapshot.book.sceneSummary)
                        .font(.captionLarge)
                        .foregroundStyle(snapshot.book.palette.primary)
                }

                Spacer()

                SceneAccentBadge(text: "\(snapshot.progress.completedChapterIds.count) 章已攻略", color: snapshot.book.palette.secondary)
            }

            HStack(spacing: .spacing12) {
                ArchiveValueBlock(title: "路线", value: "\(snapshot.routeCount)")
                ArchiveValueBlock(title: "当前", value: snapshot.currentChapterLabel)
                ArchiveValueBlock(title: "进度", value: "\(Int(snapshot.completionRatio * 100))%")
            }

            Button("打开档案", action: onOpen)
                .buttonStyle(.secondary)
        }
        .frame(width: 286, alignment: .leading)
        .scenePanel(accent: snapshot.book.palette.primary, padding: .spacing18)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}

private struct ArchiveValueBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing4) {
            Text(title)
                .font(.captionSmall)
                .foregroundStyle(Color.textTertiary)

            Text(value)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacing12)
        .background(
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(Color.surfaceSecondary.opacity(0.88))
        )
    }
}

private struct CuratedStageCard: View {
    let book: Book
    let snapshot: HomeProgressSnapshot?
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: .radiusXLarge, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                book.palette.primary.opacity(0.32),
                                book.palette.secondary.opacity(0.18),
                                Color.surfaceSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 286, height: 208)

                VStack(alignment: .leading, spacing: .spacing8) {
                    SceneAccentBadge(
                        text: snapshot == nil ? book.genre.displayName : "在读 · \(snapshot?.currentChapterLabel ?? "")",
                        color: book.palette.primary
                    )

                    Text(book.title)
                        .font(.titleLarge)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)

                    Text(book.genre.controlPrompt)
                        .font(.captionLarge)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
                .padding(.spacing18)
            }

            HStack(spacing: .spacing10) {
                TagFlowView(tags: Array(book.interactionTags.prefix(2)), color: book.palette.tertiary)
            }

            Button(snapshot == nil ? "查看这本故事" : "回到这本故事", action: onOpen)
                .buttonStyle(.secondary)
        }
        .frame(width: 286, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}

private struct GenreMonumentCard: View {
    let genre: Book.Genre

    var body: some View {
        VStack(alignment: .leading, spacing: .spacing12) {
            HStack {
                Image(systemName: genre.iconName)
                    .font(.bodyLarge)
                    .foregroundStyle(genre.palette.primary)

                Spacer()

                SceneAccentBadge(text: genre.sceneName, color: genre.palette.secondary)
            }

            Text(genre.displayName)
                .font(.labelLarge)
                .foregroundStyle(Color.textPrimary)

            Text(genre.controlPrompt)
                .font(.captionLarge)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .scenePanel(accent: genre.palette.primary, padding: .spacing16)
    }
}

private struct StoryVaultCard: View {
    let book: Book
    let snapshot: HomeProgressSnapshot?
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: .spacing16) {
            RoundedRectangle(cornerRadius: .radiusLarge, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            book.palette.primary.opacity(0.28),
                            book.palette.secondary.opacity(0.16),
                            Color.surfaceSecondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 136)
                .overlay(
                    Text(String(book.title.prefix(1)))
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(book.palette.primary)
                )

            VStack(alignment: .leading, spacing: .spacing10) {
                VStack(alignment: .leading, spacing: .spacing4) {
                    HStack(spacing: .spacing8) {
                        Text(book.title)
                            .font(.titleSmall)
                            .foregroundStyle(Color.textPrimary)
                            .accessibilityAddTraits(.isStaticText)

                        if let snapshot {
                            SceneAccentBadge(text: snapshot.currentChapterLabel, color: book.palette.secondary)
                        }
                    }

                    Text(book.sceneSummary)
                        .font(.captionLarge)
                        .foregroundStyle(book.palette.primary)

                    Text(book.synopsis)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(3)
                        .lineSpacing(3)
                }

                TagFlowView(tags: Array(book.tags.prefix(3)), color: book.palette.secondary)

                Button(snapshot == nil ? "查看角色与章节" : "打开详情与攻略", action: onOpen)
                    .buttonStyle(.secondary)
            }
        }
        .scenePanel(accent: book.palette.primary, padding: .spacing16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }
}
