import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var title: String
    var amount: Double
    var note: String
    var date: Date
    var isIncome: Bool
    var categoryRawValue: String

    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        title: String,
        amount: Double,
        note: String = "",
        date: Date = .now,
        isIncome: Bool,
        category: TransactionCategory = .other
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.note = note
        self.date = date
        self.isIncome = isIncome
        self.categoryRawValue = category.rawValue
    }
}
