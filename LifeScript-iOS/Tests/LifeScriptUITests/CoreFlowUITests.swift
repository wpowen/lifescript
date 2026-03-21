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
        let bookCard = app.staticTexts["龙隐都市"].firstMatch
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        bookCard.tap()

        // Should show book detail with start reading button
        let startButton = app.buttons["开始阅读"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
    }

    func test_startReading_showsChapterContent() {
        // Navigate to book detail
        let bookCard = app.staticTexts["龙隐都市"].firstMatch
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        bookCard.tap()

        // Wait for chapters to load, then tap start reading
        let chapterRow = app.staticTexts["宗祠之辱"]
        XCTAssertTrue(chapterRow.waitForExistence(timeout: 5), "Expected chapter list to load")

        let startButton = app.buttons["开始阅读"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        // Should see chapter header in reading view
        let chapterNumber = app.staticTexts["第1章"]
        XCTAssertTrue(chapterNumber.waitForExistence(timeout: 5), "Expected reading view to appear")
    }
}
