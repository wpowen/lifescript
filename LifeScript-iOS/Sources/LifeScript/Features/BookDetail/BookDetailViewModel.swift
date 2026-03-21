import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class BookDetailViewModel {

    let book: Book
    private(set) var chapters: [Chapter] = []
    private(set) var isLoading = false
    private(set) var hasProgress = false

    private let contentLoader: ContentProviding

    init(book: Book, contentLoader: ContentProviding = BundledContentLoader()) {
        self.book = book
        self.contentLoader = contentLoader
    }

    func onAppear() async {
        isLoading = true
        defer { isLoading = false }
        do {
            chapters = try await contentLoader.loadAllChapters(bookId: book.id)
        } catch {
            // Fail silently for chapter list — book details are still visible
            chapters = []
        }
    }

    var firstChapterId: String? {
        chapters.first?.id
    }
}
