import SwiftUI

struct NotionBlock<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .contentShape(Rectangle())
    }
}

struct NotionHeading: View {
    let text: String
    var level: HeadingLevel = .h2

    enum HeadingLevel {
        case h1, h2, h3
    }

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.semibold)
            .foregroundStyle(Color.notionText)
            .padding(.horizontal, 16)
            .padding(.top, level == .h1 ? 24 : 16)
            .padding(.bottom, 4)
    }

    private var font: Font {
        switch level {
        case .h1: return .title
        case .h2: return .title3
        case .h3: return .headline
        }
    }
}

struct NotionTag: View {
    let text: String
    let color: Color
    let backgroundColor: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
