import Foundation
import SwiftUI
import SwiftData

@Observable
final class TransactionViewModel {
    var selectedPeriod: TimePeriod = .month

    enum TimePeriod: String, CaseIterable {
        case week = "Неделя"
        case month = "Месяц"
        case year = "Год"
        case all = "Все"
    }

    func totalIncome(from transactions: [Transaction]) -> Double {
        filteredTransactions(from: transactions)
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    func totalExpense(from transactions: [Transaction]) -> Double {
        filteredTransactions(from: transactions)
            .filter { !$0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    func filteredTransactions(from transactions: [Transaction]) -> [Transaction] {
        let now = Date()
        let calendar = Calendar.current

        return transactions.filter { transaction in
            switch selectedPeriod {
            case .week:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return transaction.date >= weekAgo
            case .month:
                return transaction.date >= now.startOfMonth
            case .year:
                let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
                return transaction.date >= yearStart
            case .all:
                return true
            }
        }
    }

    func groupedByDate(from transactions: [Transaction]) -> [(String, [Transaction])] {
        let filtered = filteredTransactions(from: transactions)
            .sorted { $0.date > $1.date }

        let grouped = Dictionary(grouping: filtered) { transaction in
            transaction.date.relativeDescription
        }

        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let date1 = grouped[key1]?.first?.date ?? .distantPast
            let date2 = grouped[key2]?.first?.date ?? .distantPast
            return date1 > date2
        }

        return sortedKeys.map { key in
            (key, grouped[key] ?? [])
        }
    }

    func expensesByCategory(from transactions: [Transaction]) -> [(TransactionCategory, Double)] {
        let expenses = filteredTransactions(from: transactions).filter { !$0.isIncome }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return grouped.map { (key, value) in
            (key, value.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.1 > $1.1 }
    }
}
