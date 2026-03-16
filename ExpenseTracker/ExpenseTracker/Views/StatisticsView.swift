import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var viewModel = TransactionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.notionBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Period picker
                        periodPicker
                            .padding(.top, 8)

                        // Summary cards
                        summaryCards

                        // Expenses by category
                        NotionHeading(text: "Расходы по категориям", level: .h3)
                        categoryBreakdown

                        // Recent activity
                        NotionHeading(text: "Последние транзакции", level: .h3)
                        recentTransactions

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionViewModel.TimePeriod.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedPeriod = period
                        }
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                            .foregroundStyle(
                                viewModel.selectedPeriod == period
                                    ? Color.notionSecondaryBg
                                    : Color.notionSecondaryText
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedPeriod == period
                                    ? Color.notionAccent
                                    : Color.notionSecondaryBg
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.notionBorder, lineWidth: viewModel.selectedPeriod == period ? 0 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCardView(
                title: "Доходы",
                amount: viewModel.totalIncome(from: transactions),
                icon: "arrow.down.circle.fill",
                color: .notionGreen,
                backgroundColor: .notionGreenBg
            )

            SummaryCardView(
                title: "Расходы",
                amount: viewModel.totalExpense(from: transactions),
                icon: "arrow.up.circle.fill",
                color: .notionRed,
                backgroundColor: .notionRedBg
            )
        }
        .padding(.horizontal, 16)
    }

    private var categoryBreakdown: some View {
        let categories = viewModel.expensesByCategory(from: transactions)
        let totalExpense = viewModel.totalExpense(from: transactions)

        return Group {
            if categories.isEmpty {
                NotionCard {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.pie")
                                .font(.title2)
                                .foregroundStyle(Color.notionBorder)
                            Text("Нет данных")
                                .font(.caption)
                                .foregroundStyle(Color.notionSecondaryText)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 16)
            } else {
                NotionCard {
                    VStack(spacing: 12) {
                        ForEach(categories, id: \.0) { category, amount in
                            categoryRow(
                                category: category,
                                amount: amount,
                                total: totalExpense
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func categoryRow(category: TransactionCategory, amount: Double, total: Double) -> some View {
        let percentage = total > 0 ? amount / total : 0

        return VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(category.color)
                    .frame(width: 24)

                Text(category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.notionText)

                Spacer()

                Text(String(format: "%.0f \u{20BD}", amount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.notionText)

                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.caption)
                    .foregroundStyle(Color.notionSecondaryText)
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.notionBorder)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(category.color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    private var recentTransactions: some View {
        let recent = Array(viewModel.filteredTransactions(from: transactions)
            .sorted { $0.date > $1.date }
            .prefix(5))

        return Group {
            if recent.isEmpty {
                NotionCard {
                    HStack {
                        Spacer()
                        Text("Нет транзакций")
                            .font(.caption)
                            .foregroundStyle(Color.notionSecondaryText)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(recent, id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != recent.last?.id {
                            NotionDivider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color.notionSecondaryBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.notionBorder, lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }
}
