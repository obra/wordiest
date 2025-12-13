import Foundation

enum PrettyRelativeTime {
    static func format(target: Date, relativeTo base: Date) -> String {
        let seconds = target.timeIntervalSince(base)
        let isFuture = seconds > 0
        let s = abs(seconds)

        func ago(_ text: String) -> String { isFuture ? "in \(text)" : "\(text) ago" }
        func count(_ value: Int, singular: String, plural: String) -> String {
            if value == 1 { return singular }
            return "\(value) \(plural)"
        }

        if s < 45 {
            return isFuture ? "in moments" : "moments ago"
        }
        if s < 90 {
            return isFuture ? "in a minute" : "a minute ago"
        }
        if s < 45 * 60 {
            let minutes = Int(round(s / 60))
            return ago(count(minutes, singular: "a minute", plural: "minutes"))
        }
        if s < 90 * 60 {
            return isFuture ? "in an hour" : "an hour ago"
        }
        if s < 22 * 3600 {
            let hours = Int(round(s / 3600))
            return ago(count(hours, singular: "an hour", plural: "hours"))
        }
        if s < 36 * 3600 {
            return isFuture ? "in a day" : "a day ago"
        }
        if s < 26 * 86400 {
            let days = Int(round(s / 86400))
            return ago(count(days, singular: "a day", plural: "days"))
        }
        if s < 45 * 86400 {
            return isFuture ? "in a month" : "a month ago"
        }
        if s < 320 * 86400 {
            let months = Int(round(s / (30 * 86400)))
            return ago(count(months, singular: "a month", plural: "months"))
        }
        if s < 548 * 86400 {
            return isFuture ? "in a year" : "a year ago"
        }

        let years = Int(round(s / (365 * 86400)))
        return ago(count(years, singular: "a year", plural: "years"))
    }
}

