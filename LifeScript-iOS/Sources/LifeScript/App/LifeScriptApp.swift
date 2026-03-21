import SwiftUI
import SwiftData

@main
struct LifeScriptApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(coordinator)
                .preferredColorScheme(.dark) // Dark atmospheric theme
        }
        .modelContainer(for: [
            ReadingProgress.self,
        ])
    }
}
