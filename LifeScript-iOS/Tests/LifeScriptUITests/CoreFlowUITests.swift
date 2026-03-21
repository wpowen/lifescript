import XCTest

final class CoreFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func test_homeScreen_displaysBookList() {
        // Home tab should display at least one book
        let firstBook = app.staticTexts["龙隐都市"]
        XCTAssertTrue(firstBook.waitForExistence(timeout: 5), "Expected book title to appear on home screen")
    }

    func test_navigateToBookDetail() {
        let bookCard = app.staticTexts["龙隐都市"]
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        bookCard.tap()

        // Should show book detail with start reading button
        let startButton = app.buttons["开始阅读"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
    }

    func test_startReading_showsChapterContent() {
        // Navigate to book detail
        let bookCard = app.staticTexts["龙隐都市"]
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        bookCard.tap()

        // Start reading
        let startButton = app.buttons["开始阅读"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        // Should see chapter content
        let chapterTitle = app.staticTexts["宗祠之辱"]
        XCTAssertTrue(chapterTitle.waitForExistence(timeout: 5), "Expected chapter title to appear")
    }
}
