import SwiftUI
import XCTest
@testable import LifeScriptSolo

final class SoloCharacterResponsiveLayoutTests: XCTestCase {
    func test_compactLayout_stacksSidebarAndUsesSingleColumnRoster() {
        let layout = SoloCharacterResponsiveLayout(horizontalSizeClass: .compact)

        XCTAssertTrue(layout.isCompact)
        XCTAssertFalse(layout.usesSidebarColumn)
        XCTAssertEqual(layout.rosterColumnCount, 1)
        XCTAssertEqual(layout.detailMetricColumnCount, 2)
        XCTAssertEqual(layout.heartRingColumnCount, 1)
        XCTAssertNil(layout.sidebarWidth)
    }

    func test_regularLayout_keepsSidebarAndUsesTwoColumnRoster() {
        let layout = SoloCharacterResponsiveLayout(horizontalSizeClass: .regular)

        XCTAssertFalse(layout.isCompact)
        XCTAssertTrue(layout.usesSidebarColumn)
        XCTAssertEqual(layout.rosterColumnCount, 2)
        XCTAssertEqual(layout.detailMetricColumnCount, 3)
        XCTAssertEqual(layout.heartRingColumnCount, 2)
        XCTAssertEqual(layout.sidebarWidth, 220)
    }
}

