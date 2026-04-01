import Observation
import SwiftUI

enum SoloRoute: Hashable {
    case reading(String)
    case volumeGate(String)
    case chapterBrowser
    case dossier
    case routeMap
    case destinyAtlas
    case humanHearts
    case darklineBoard
    case settings
}

@Observable
final class SoloCoordinator {
    var path = NavigationPath()

    func open(_ route: SoloRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
