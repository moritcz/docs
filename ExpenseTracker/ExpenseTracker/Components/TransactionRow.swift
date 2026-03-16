import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(transaction.category.color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(transaction.category.color)
            }

            // Title and category
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.notionText)
                    .lineLimit(1)

                Text(transaction.category.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.notionSecondaryText)
            }

            Spacer()

            // Amount and time
            VStack(alignment: .trailing, spacing: 3) {
                Text(formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.isIncome ? Color.notionGreen : Color.notionText)

                Text(transaction.date.formatted(as: .time))
                    .font(.caption)
                    .foregroundStyle(Color.notionSecondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.notionSecondaryBg)
        .contentShape(Rectangle())
    }

    private var formattedAmount: String {
        let sign = transaction.isIncome ? "+" : "-"
        let formatted = String(format: "%.0f", transaction.amount)
        return "\(sign) \(formatted) \u{20BD}"
    }
}
