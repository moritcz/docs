import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var isIncome = false
    @State private var category: TransactionCategory = .food

    var body: some View {
        NavigationStack {
            ZStack {
                Color.notionBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Type toggle
                        typeToggle
                            .padding(.top, 8)

                        // Amount field
                        amountField

                        // Title field
                        notionTextField(
                            icon: "pencil",
                            placeholder: "Название",
                            text: $title
                        )

                        // Category picker
                        NotionCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "tag")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.notionSecondaryText)
                                    Text("Категория")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.notionSecondaryText)
                                }

                                CategoryPickerView(
                                    selected: $category,
                                    isIncome: isIncome
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // Date picker
                        NotionCard {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.notionSecondaryText)
                                Text("Дата")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.notionSecondaryText)
                                Spacer()
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .tint(Color.notionAccent)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Note field
                        notionTextField(
                            icon: "text.alignleft",
                            placeholder: "Заметка (необязательно)",
                            text: $note
                        )
                    }
                    .padding(.bottom, 100)
                }

                // Save button
                VStack {
                    Spacer()
                    saveButton
                }
            }
            .navigationTitle("Новая запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundStyle(Color.notionSecondaryText)
                }
            }
        }
    }

    private var typeToggle: some View {
        HStack(spacing: 0) {
            typeButton(title: "Расход", isSelected: !isIncome) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isIncome = false
                    category = .food
                }
            }
            typeButton(title: "Доход", isSelected: isIncome) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isIncome = true
                    category = .salary
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

    private func typeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.notionSecondaryBg : Color.notionSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.notionAccent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
    }

    private var amountField: some View {
        NotionCard {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(isIncome ? "+" : "-")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(isIncome ? Color.notionGreen : Color.notionRed)

                    TextField("0", text: $amount)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.notionText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)

                    Text("\u{20BD}")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color.notionSecondaryText)
                }

                Text("Введите сумму")
                    .font(.caption)
                    .foregroundStyle(Color.notionSecondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
    }

    private func notionTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        NotionCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.notionSecondaryText)

                TextField(placeholder, text: text)
                    .font(.subheadline)
                    .foregroundStyle(Color.notionText)
            }
        }
        .padding(.horizontal, 16)
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Сохранить")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isValid
                        ? Color.notionAccent
                        : Color.notionSecondaryText
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isValid)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.notionBackground.opacity(0), Color.notionBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .offset(y: -40)
        , alignment: .top)
    }

    private var isValid: Bool {
        !title.isEmpty && (Double(amount) ?? 0) > 0
    }

    private func save() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        let transaction = Transaction(
            title: title,
            amount: amountValue,
            note: note,
            date: date,
            isIncome: isIncome,
            category: category
        )

        modelContext.insert(transaction)
        dismiss()
    }
}
