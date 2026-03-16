import SwiftUI

struct NotionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(Color.notionSecondaryBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.notionBorder, lineWidth: 1)
            )
    }
}

struct NotionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.notionBorder)
            .frame(height: 1)
    }
}
