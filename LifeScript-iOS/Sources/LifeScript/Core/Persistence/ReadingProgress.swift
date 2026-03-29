import Foundation
import SwiftData

/// Persists the user's reading progress for a book
@Model
final class ReadingProgress {
    @Attribute(.unique) var bookId: String
    var currentChapterId: String
    var currentNodeIndex: Int
    var lastReadDate: Date
    var completedChapterIds: [String]

    /// Serialized protagonist stats (JSON)
    var statsJSON: Data?

    /// Serialized relationship states (JSON)
    var relationshipsJSON: Data?

    /// Serialized choice records (JSON)
    var choicesJSON: Data?

    init(
        bookId: String,
        currentChapterId: String,
        currentNodeIndex: Int = 0
    ) {
        self.bookId = bookId
        self.currentChapterId = currentChapterId
        self.currentNodeIndex = currentNodeIndex
        self.lastReadDate = Date()
        self.completedChapterIds = []
    }

    // MARK: - Stats

    var stats: ProtagonistStats? {
        get {
            guard let data = statsJSON else { return nil }
            return try? JSONDecoder().decode(ProtagonistStats.self, from: data)
        }
        set {
            statsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Relationships

    var relationships: [RelationshipState]? {
        get {
            guard let data = relationshipsJSON else { return nil }
            return try? JSONDecoder().decode([RelationshipState].self, from: data)
        }
        set {
            relationshipsJSON = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Choices

    var choiceRecords: [UserChoiceRecord]? {
        get {
            guard let data = choicesJSON else { return nil }
            return try? JSONDecoder().decode([UserChoiceRecord].self, from: data)
        }
        set {
            choicesJSON = try? JSONEncoder().encode(newValue)
        }
    }
}

/// Records a user's choice at a specific interaction point
struct UserChoiceRecord: Codable, Identifiable, Sendable {
    var id: String { "\(chapterId)_\(choiceNodeId)" }
    let chapterId: String
    let choiceNodeId: String
    let selectedChoiceId: String
    let timestamp: Date
}

@MainActor
enum StoryContentVersioning {
    static func reconcilePersistedProgress(
        bookId: String,
        contentLoader: ContentProviding,
        modelContext: ModelContext
    ) async {
        guard let contentVersion = try? await contentLoader.loadContentVersion(bookId: bookId),
              !contentVersion.isEmpty else {
            return
        }

        let defaultsKey = versionDefaultsKey(for: bookId)
        let defaults = UserDefaults.standard
        let recordedVersion = defaults.string(forKey: defaultsKey)

        guard recordedVersion != contentVersion else {
            return
        }

        let descriptor = FetchDescriptor<ReadingProgress>(
            predicate: #Predicate { $0.bookId == bookId }
        )

        if let progress = try? modelContext.fetch(descriptor).first {
            modelContext.delete(progress)
            try? modelContext.save()
        }

        defaults.set(contentVersion, forKey: defaultsKey)
    }

    static func versionDefaultsKey(for bookId: String) -> String {
        "story-content-version.\(bookId)"
    }
}
