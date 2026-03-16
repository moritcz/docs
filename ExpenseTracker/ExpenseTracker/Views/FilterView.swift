import SwiftUI

struct FilterView: View {
    @Binding var selectedPeriod: TransactionViewModel.TimePeriod
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.notionBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    NotionHeading(text: "Период", level: .h3)

                    ForEach(TransactionViewModel.TimePeriod.allCases, id: \.self) { period in
                        Button {
                            selectedPeriod = period
                            dismiss()
                        } label: {
                            HStack {
                                Text(period.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.notionText)
                                Spacer()
                                if selectedPeriod == period {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.notionAccent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        NotionDivider()
                            .padding(.horizontal, 16)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Фильтр")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(Color.notionAccent)
                }
            }
        }
    }
}
