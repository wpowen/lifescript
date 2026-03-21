import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {

    enum ViewState {
        case idle
        case loading
        case loaded([Book])
        case error(String)

        var books: [Book] {
            if case .loaded(let books) = self { return books }
            return []
        }

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }
    }

    private(set) var state: ViewState = .idle
    private(set) var featuredBooks: [Book] = []
    private(set) var recentlyReading: [Book] = []

    private let contentLoader: ContentProviding

    init(contentLoader: ContentProviding = BundledContentLoader()) {
        self.contentLoader = contentLoader
    }

    func onAppear() async {
        guard case .idle = state else { return }
        await loadBooks()
    }

    func onRefresh() async {
        await loadBooks()
    }

    private func loadBooks() async {
        state = .loading
        do {
            let books = try await contentLoader.listBooks()
            state = .loaded(books)
            featuredBooks = Array(books.prefix(3))
        } catch {
            state = .error(AppError.from(error).localizedDescription)
        }
    }
}
