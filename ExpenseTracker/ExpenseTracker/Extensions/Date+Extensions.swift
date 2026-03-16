import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    func formatted(as style: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        switch style {
        case .dayMonth:
            formatter.dateFormat = "d MMM"
        case .full:
            formatter.dateFormat = "d MMMM yyyy"
        case .monthYear:
            formatter.dateFormat = "LLLL yyyy"
        case .time:
            formatter.dateFormat = "HH:mm"
        case .dayOfWeek:
            formatter.dateFormat = "EEEE"
        }
        return formatter.string(from: self)
    }

    enum DateFormatStyle {
        case dayMonth, full, monthYear, time, dayOfWeek
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var relativeDescription: String {
        if isToday { return "Сегодня" }
        if isYesterday { return "Вчера" }
        return formatted(as: .dayMonth)
    }
}
