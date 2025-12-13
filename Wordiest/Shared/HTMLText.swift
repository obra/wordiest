import SwiftUI

struct HTMLText: View {
    var html: String
    var textColor: Color

    var body: some View {
        Text(attributed())
            .foregroundStyle(textColor)
    }

    private func attributed() -> AttributedString {
        guard let data = html.data(using: .utf8) else { return AttributedString(html) }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        if let ns = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return AttributedString(ns)
        }
        return AttributedString(html)
    }
}

