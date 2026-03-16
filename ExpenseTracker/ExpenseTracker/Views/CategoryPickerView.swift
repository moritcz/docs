import SwiftUI

struct CategoryPickerView: View {
    @Binding var selected: TransactionCategory
    let isIncome: Bool

    private var categories: [TransactionCategory] {
        isIncome ? TransactionCategory.incomeCategories : TransactionCategory.expenseCategories
    }

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(categories) { category in
                categoryChip(category)
            }
        }
    }

    private func categoryChip(_ category: TransactionCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected = category
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))

                Text(category.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(selected == category ? .white : category.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selected == category
                    ? category.color
                    : category.color.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
