import SwiftUI

struct SummaryCardView: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    let backgroundColor: Color

    var body: some View {
        NotionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.notionSecondaryText)
                }

                Text(formattedAmount)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.notionText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedAmount: String {
        let formatted = String(format: "%.0f", amount)
        return "\(formatted) \u{20BD}"
    }
}

struct BalanceCardView: View {
    let income: Double
    let expense: Double

    private var balance: Double { income - expense }

    var body: some View {
        NotionCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Баланс")
                        .font(.subheadline)
                        .foregroundStyle(Color.notionSecondaryText)
                    Spacer()
                    Text(Date.now.formatted(as: .monthYear).capitalized)
                        .font(.caption)
                        .foregroundStyle(Color.notionSecondaryText)
                }

                Text(formattedBalance)
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(balance >= 0 ? Color.notionGreen : Color.notionRed)

                NotionDivider()

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.notionGreen)
                            Text("Доходы")
                                .font(.caption)
                                .foregroundStyle(Color.notionSecondaryText)
                        }
                        Text(formatAmount(income))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.notionGreen)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.notionRed)
                            Text("Расходы")
                                .font(.caption)
                                .foregroundStyle(Color.notionSecondaryText)
                        }
                        Text(formatAmount(expense))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.notionRed)
                    }
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.notionBorder)
                            .frame(height: 6)

                        if income > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    expense / income > 0.8
                                        ? Color.notionRed
                                        : Color.notionGreen
                                )
                                .frame(
                                    width: geometry.size.width * min(expense / max(income, 1), 1.0),
                                    height: 6
                                )
                        }
                    }
                }
                .frame(height: 6)
            }
        }
    }

    private var formattedBalance: String {
        let sign = balance >= 0 ? "+" : ""
        return "\(sign)\(formatAmount(balance))"
    }

    private func formatAmount(_ value: Double) -> String {
        let formatted = String(format: "%.0f", abs(value))
        return "\(formatted) \u{20BD}"
    }
}
