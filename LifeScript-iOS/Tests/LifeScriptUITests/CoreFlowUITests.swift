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

        // Should enter the immersive reading view and show opening chapter content
        let immersiveView = app.scrollViews["immersiveReadingView"].firstMatch
        XCTAssertTrue(immersiveView.waitForExistence(timeout: 5), "Expected immersive reading content to appear")
    }

    func test_readingView_canReturnToPreviousPage() {
        let bookCard = app.staticTexts["龙隐都市"].firstMatch
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        bookCard.tap()

        let startButton = app.buttons["开始阅读"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let backButton = app.buttons["readingBackButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()

        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Expected to return to book detail page")
    }

    func test_readingView_canReturnToHome() {
        let bookCard = app.staticTexts["龙隐都市"].firstMatch
        XCTAssertTrue(bookCard.waitForExistence(timeout: 5))
        bookCard.tap()

        let startButton = app.buttons["开始阅读"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let homeButton = app.buttons["readingHomeButton"]
        XCTAssertTrue(homeButton.waitForExistence(timeout: 5))
        homeButton.tap()

        XCTAssertTrue(app.tabBars.buttons["故事"].waitForExistence(timeout: 3), "Expected home tab bar to be visible again")
        XCTAssertFalse(app.buttons["开始阅读"].waitForExistence(timeout: 1), "Expected to leave the book detail page when returning home")
        XCTAssertFalse(app.buttons["readingHomeButton"].exists, "Expected to leave the immersive reading page when returning home")
    }
}
