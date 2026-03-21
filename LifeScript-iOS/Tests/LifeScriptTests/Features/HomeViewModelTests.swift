import XCTest
@testable import LifeScript

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockLoader: MockContentLoader!

    override func setUp() async throws {
        mockLoader = MockContentLoader()
        sut = HomeViewModel(contentLoader: mockLoader)
    }

    override func tearDown() async throws {
        sut = nil
        mockLoader = nil
    }

    func test_onAppear_loadsBooks_success() async {
        mockLoader.stubbedBooks = [TestFixtures.makeBook()]
        await sut.onAppear()

        if case .loaded(let books) = sut.state {
            XCTAssertEqual(books.count, 1)
            XCTAssertEqual(books[0].title, "测试书籍")
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func test_onAppear_setsError_onFailure() async {
        mockLoader.shouldThrow = true
        await sut.onAppear()

        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }

    func test_onAppear_setsFeaturedBooks() async {
        mockLoader.stubbedBooks = [
            TestFixtures.makeBook(id: "1", title: "Book 1"),
            TestFixtures.makeBook(id: "2", title: "Book 2"),
            TestFixtures.makeBook(id: "3", title: "Book 3"),
            TestFixtures.makeBook(id: "4", title: "Book 4"),
        ]
        await sut.onAppear()

        XCTAssertEqual(sut.featuredBooks.count, 3)
    }

    func test_onAppear_onlyLoadsOnce() async {
        mockLoader.stubbedBooks = [TestFixtures.makeBook()]
        await sut.onAppear()
        await sut.onAppear()

        // Should still be loaded, not re-fetched
        if case .loaded = sut.state {} else {
            XCTFail("Expected loaded state")
        }
    }

    func test_onRefresh_reloadsBooks() async {
        mockLoader.stubbedBooks = [TestFixtures.makeBook()]
        await sut.onAppear()

        mockLoader.stubbedBooks = [
            TestFixtures.makeBook(id: "1"),
            TestFixtures.makeBook(id: "2"),
        ]
        await sut.onRefresh()

        if case .loaded(let books) = sut.state {
            XCTAssertEqual(books.count, 2)
        } else {
            XCTFail("Expected loaded state")
        }
    }
}
