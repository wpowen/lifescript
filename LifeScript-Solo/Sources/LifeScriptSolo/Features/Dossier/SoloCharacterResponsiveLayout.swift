import SwiftUI

struct SoloCharacterResponsiveLayout: Equatable {
    let isCompact: Bool
    let usesSidebarColumn: Bool
    let rosterColumnCount: Int
    let detailMetricColumnCount: Int
    let heartRingColumnCount: Int
    let sidebarWidth: CGFloat?

    init(horizontalSizeClass: UserInterfaceSizeClass?) {
        let isRegular = horizontalSizeClass == .regular
        self.isCompact = !isRegular
        self.usesSidebarColumn = isRegular
        self.rosterColumnCount = isRegular ? 2 : 1
        self.detailMetricColumnCount = isRegular ? 3 : 2
        self.heartRingColumnCount = isRegular ? 2 : 1
        self.sidebarWidth = isRegular ? 220 : nil
    }
}

