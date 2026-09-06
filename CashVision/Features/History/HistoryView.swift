import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel
    @Environment(SettingsStore.self) private var settings
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView(
                        "История пуста",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Здесь появятся результаты пересчёта и проверки банкнот")
                    )
                } else {
                    List {
                        ForEach(viewModel.entries) { entry in
                            HistoryRowView(entry: entry)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewModel.remove(entry)
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("История")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView(settings: settings)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                if !viewModel.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Очистить") {
                            showClearConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog("Очистить всю историю?", isPresented: $showClearConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) {
                    viewModel.clearAll()
                }
            }
        }
    }
}

struct HistoryRowView: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dateFormatter.string(from: entry.date))
                    .font(.subheadline.bold())
                Spacer()
                Text(amountFormatter.string(from: NSNumber(value: entry.totalAmount)) ?? "\(entry.totalAmount) ₽")
                    .font(.headline)
                    .foregroundStyle(.accent)
            }
            HStack {
                Text(timeFormatter.string(from: entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Режим: \(entry.mode == "count" ? "Пересчёт" : "Проверка")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(entry.denominations) { denom in
                Text(denom.formatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }
    private var amountFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        return f
    }
}
