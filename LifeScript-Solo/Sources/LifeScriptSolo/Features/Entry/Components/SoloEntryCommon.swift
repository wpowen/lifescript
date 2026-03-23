import SwiftUI

struct SoloEntrySectionHeader: View {
    let eyebrow: String?
    let title: String
    let detail: String?

    var body: some View {
        SoloSectionHeading(eyebrow: eyebrow, title: title, detail: detail)
    }
}

struct SoloEntryMetaChip: View {
    let text: String
    let tint: Color

    var body: some View {
        SoloSignalChip(text: text, tint: tint)
    }
}

struct SoloEntrySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SoloGhostActionButtonStyle().makeBody(configuration: configuration)
    }
}
