import Foundation
import UIKit

enum Wiktionary {
    static func url(for lookupWord: String) -> URL? {
        guard !lookupWord.isEmpty else { return nil }
        guard let escaped = lookupWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "https://en.m.wiktionary.org/wiki/\(escaped)#English")
    }

    static func open(lookupWord: String) {
        guard let url = url(for: lookupWord) else { return }
        UIApplication.shared.open(url)
    }
}

