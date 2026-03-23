import SwiftUI
import SwiftData

@main
struct LifeScriptSoloApp: App {
    var body: some Scene {
        WindowGroup {
            SoloRootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            ReadingProgress.self,
        ])
    }
}
