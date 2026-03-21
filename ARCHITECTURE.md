# Architecture Decision Record: 命书 (LifeScript) iOS

## Decision: Architecture Pattern
**Chosen**: MVVM + Coordinator
**Rationale**: 10+ screens but state flows are mostly linear (reading flow). No complex cross-feature state beyond the reading session. Coordinator handles navigation between discovery, reading, and profile flows.

## Decision: UI Framework
**Chosen**: SwiftUI
**Target iOS**: 17.0+
**Rationale**: Modern declarative UI, @Observable support, SwiftData integration

## Decision: State Management
**Chosen**: @Observable (Observation framework)
**Rationale**: iOS 17+, zero boilerplate, clean integration with SwiftUI views

## Decision: Persistence
**Chosen**: SwiftData
**Usage**: Reading progress, user choices, protagonist stats, relationship states, bookshelf
**Rationale**: Native iOS 17+ persistence, handles relationships well for character/choice data

## Decision: Content Delivery
**Chosen**: Local JSON bundles (MVP), designed for future REST API migration
**Rationale**: MVP ships with bundled content. Content models use Codable so switching to API is trivial.

## Decision: Networking
**Chosen**: URLSession + async/await (prepared but unused in MVP)
**Rationale**: No backend for MVP, but API client skeleton ready for V2

## Decision: Backend
**Chosen**: Local only (MVP)
**Future**: REST API for content delivery, user sync, payments

## Module Breakdown

```
LifeScript-iOS/
├── Sources/LifeScript/
│   ├── App/                          # Entry point, coordinator, tab bar
│   │   ├── LifeScriptApp.swift
│   │   ├── AppCoordinator.swift
│   │   └── MainTabView.swift
│   ├── DesignSystem/                 # Tokens + reusable components
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   └── Components/
│   │       ├── ButtonStyles.swift
│   │       ├── TagView.swift
│   │       ├── StatBar.swift
│   │       └── EmptyStateView.swift
│   ├── Models/                       # Domain models (Codable for JSON content)
│   │   ├── Book.swift
│   │   ├── Chapter.swift
│   │   ├── StoryNode.swift
│   │   ├── Choice.swift
│   │   ├── Character.swift
│   │   ├── ProtagonistStats.swift
│   │   └── RelationshipState.swift
│   ├── Core/
│   │   ├── Content/                  # JSON content loader
│   │   │   └── ContentLoader.swift
│   │   ├── Persistence/              # SwiftData models for user state
│   │   │   ├── ReadingProgress.swift
│   │   │   ├── UserChoiceRecord.swift
│   │   │   └── UserStatsRecord.swift
│   │   └── Network/                  # API skeleton (future)
│   │       ├── APIClient.swift
│   │       └── AppError.swift
│   ├── Features/
│   │   ├── Home/                     # Discovery & recommendations
│   │   ├── BookDetail/               # Book info & start reading
│   │   ├── Reading/                  # Core reading experience
│   │   ├── Stats/                    # Protagonist attributes
│   │   ├── Relationships/            # Character relationship panel
│   │   ├── ChapterSettlement/        # End-of-chapter summary
│   │   ├── Bookshelf/                # User's library
│   │   ├── Profile/                  # User settings
│   │   └── Auth/                     # Guest/login
│   └── Resources/
│       ├── Assets.xcassets/
│       └── SampleContent/            # Bundled JSON stories
└── Tests/
    ├── LifeScriptTests/
    └── LifeScriptUITests/
```

## Key Interfaces (Protocols)

```swift
protocol ContentProviding: Sendable {
    func loadBook(id: String) async throws -> Book
    func loadChapter(bookId: String, chapterId: String) async throws -> Chapter
    func listBooks() async throws -> [Book]
}

protocol ReadingProgressStoring {
    func save(progress: ReadingProgress)
    func load(bookId: String) -> ReadingProgress?
}

protocol StatsEngineProtocol {
    func apply(effects: [StatEffect], to stats: ProtagonistStats) -> ProtagonistStats
    func apply(effects: [RelationshipEffect], to relationships: [RelationshipState]) -> [RelationshipState]
}
```
