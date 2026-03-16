import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var viewModel = TransactionViewModel()
    @State private var searchText = ""
    @State private var filterByType: FilterType = .all

    enum FilterType: String, CaseIterable {
        case all = "Все"
        case income = "Доходы"
        case expense = "Расходы"
    }

    private var displayTransactions: [Transaction] {
        var result = viewModel.filteredTransactions(from: transactions)

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch filterByType {
        case .all: break
        case .income: result = result.filter { $0.isIncome }
        case .expense: result = result.filter { !$0.isIncome }
        }

        return result.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.notionBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Type filter
                    typeFilter

                    // Transactions
                    if displayTransactions.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(displayTransactions, id: \.id) { transaction in
                                    TransactionRow(transaction: transaction)
                                    NotionDivider()
                                }
                            }
                            .background(Color.notionSecondaryBg)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.notionBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Все записи")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.notionSecondaryText)

            TextField("Поиск...", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(Color.notionText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.notionSecondaryBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.notionBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var typeFilter: some View {
        HStack(spacing: 8) {
            ForEach(FilterType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterByType = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.caption)
                        .fontWeight(filterByType == type ? .semibold : .regular)
                        .foregroundStyle(
                            filterByType == type
                                ? Color.notionSecondaryBg
                                : Color.notionSecondaryText
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            filterByType == type
                                ? Color.notionAccent
                                : Color.notionSecondaryBg
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.notionBorder, lineWidth: filterByType == type ? 0 : 1)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(Color.notionBorder)
            Text("Ничего не найдено")
                .font(.subheadline)
                .foregroundStyle(Color.notionSecondaryText)
            Spacer()
        }
    }
}
