import Foundation
import SwiftUI

enum TransactionCategory: String, CaseIterable, Identifiable {
    case food = "food"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case health = "health"
    case education = "education"
    case bills = "bills"
    case salary = "salary"
    case freelance = "freelance"
    case investment = "investment"
    case gift = "gift"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food: return "Еда"
        case .transport: return "Транспорт"
        case .shopping: return "Покупки"
        case .entertainment: return "Развлечения"
        case .health: return "Здоровье"
        case .education: return "Образование"
        case .bills: return "Счета"
        case .salary: return "Зарплата"
        case .freelance: return "Фриланс"
        case .investment: return "Инвестиции"
        case .gift: return "Подарки"
        case .other: return "Другое"
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .bills: return "doc.text.fill"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .pink
        case .entertainment: return .purple
        case .health: return .red
        case .education: return .indigo
        case .bills: return .gray
        case .salary: return .green
        case .freelance: return .teal
        case .investment: return .mint
        case .gift: return .yellow
        case .other: return .secondary
        }
    }

    static var expenseCategories: [TransactionCategory] {
        [.food, .transport, .shopping, .entertainment, .health, .education, .bills, .gift, .other]
    }

    static var incomeCategories: [TransactionCategory] {
        [.salary, .freelance, .investment, .gift, .other]
    }
}
