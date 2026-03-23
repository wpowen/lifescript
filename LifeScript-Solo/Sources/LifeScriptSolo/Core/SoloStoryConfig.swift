import Foundation

enum SoloStoryConfig {
    static var appProfile: SoloAppProfile { SoloAppProfile.current }
    static var storyId: String { appProfile.storyID }
    static var branding: SoloBranding { appProfile.branding }
}
