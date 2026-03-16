import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TransactionViewModel()
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.notionBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Balance card
                        BalanceCardView(
                            income: viewModel.totalIncome(from: transactions),
                            expense: viewModel.totalExpense(from: transactions)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Period picker
                        periodPicker
                            .padding(.top, 20)

                        // Transactions list
                        transactionsList
                            .padding(.top, 8)

                        Spacer(minLength: 100)
                    }
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Финансы")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailSheet(transaction: transaction)
            }
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

    private var transactionsList: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            let grouped = viewModel.groupedByDate(from: transactions)

            if grouped.isEmpty {
                emptyState
            } else {
                ForEach(grouped, id: \.0) { dateString, dayTransactions in
                    Section {
                        ForEach(dayTransactions, id: \.id) { transaction in
                            TransactionRow(transaction: transaction)
                                .onTapGesture {
                                    selectedTransaction = transaction
                                }

                            if transaction.id != dayTransactions.last?.id {
                                NotionDivider()
                                    .padding(.leading, 68)
                            }
                        }
                    } header: {
                        sectionHeader(dateString)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.notionSecondaryText)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.notionBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(Color.notionBorder)

            Text("Пока нет записей")
                .font(.subheadline)
                .foregroundStyle(Color.notionSecondaryText)

            Text("Нажмите +, чтобы добавить первую транзакцию")
                .font(.caption)
                .foregroundStyle(Color.notionSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }

    private var addButton: some View {
        Button {
            showingAddTransaction = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.notionAccent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

struct TransactionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let transaction: Transaction
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.notionBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(transaction.category.color.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: transaction.category.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(transaction.category.color)
                    }
                    .padding(.top, 20)

                    // Amount
                    Text(formattedAmount)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(transaction.isIncome ? Color.notionGreen : Color.notionText)

                    // Details
                    NotionCard {
                        VStack(spacing: 12) {
                            detailRow(label: "Название", value: transaction.title)
                            NotionDivider()
                            detailRow(label: "Категория", value: transaction.category.displayName)
                            NotionDivider()
                            detailRow(label: "Тип", value: transaction.isIncome ? "Доход" : "Расход")
                            NotionDivider()
                            detailRow(label: "Дата", value: transaction.date.formatted(as: .full))
                            NotionDivider()
                            detailRow(label: "Время", value: transaction.date.formatted(as: .time))
                            if !transaction.note.isEmpty {
                                NotionDivider()
                                detailRow(label: "Заметка", value: transaction.note)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Удалить")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.notionRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.notionRedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Детали")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(Color.notionAccent)
                }
            }
            .alert("Удалить транзакцию?", isPresented: $showDeleteAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    modelContext.delete(transaction)
                    dismiss()
                }
            } message: {
                Text("Это действие нельзя отменить.")
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.notionSecondaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.notionText)
        }
    }

    private var formattedAmount: String {
        let sign = transaction.isIncome ? "+" : "-"
        let formatted = String(format: "%.0f", transaction.amount)
        return "\(sign) \(formatted) \u{20BD}"
    }
}
