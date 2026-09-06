import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel
    @Environment(SettingsStore.self) private var settings
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    ContentUnavailableView {
                        Label("История пуста", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Здесь появятся результаты пересчёта и проверки банкнот")
                    }
                } else {
                    List {
                        ForEach(viewModel.entries) { entry in
                            HistoryRowView(entry: entry)
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    Color.clear
                                )
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.top, 8)
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
                        Button("Очистить", role: .destructive) {
                            showClearConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog("Очистить всю историю?", isPresented: $showClearConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Очистить", role: .destructive) {
                    withAnimation(.cashSpring) {
                        viewModel.clearAll()
                    }
                }
            }
        }
    }
}

struct HistoryRowView: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateFormatter.string(from: entry.date))
                        .font(.subheadline.bold())
                    Text(timeFormatter.string(from: entry.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(amountFormatter.string(from: NSNumber(value: entry.totalAmount)) ?? "\(entry.totalAmount) ₽")
                    .font(.headline)
                    .foregroundStyle(.accent)
            }

            HStack {
                Text(entry.mode == "count" ? "Пересчёт" : "Проверка")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
                Spacer()
                Text("\(entry.totalCount) купюр")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !entry.denominations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.denominations) { denom in
                        HStack {
                            Text(denom.formatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "ru_RU")
        return f
    }
    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        f.locale = Locale(identifier: "ru_RU")
        return f
    }
    private var amountFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        return f
    }
}
