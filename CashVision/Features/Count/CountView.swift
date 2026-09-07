import SwiftUI
import AVFoundation
import Observation

struct CountView: View {
    let container: AppContainer
    @State private var started = false
    @State private var manualAdjustDenomination: Denomination?
    @State private var manualAdjustCount: Int = 0
    @State private var showCompletionSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: container.cameraService.captureSession)
                .ignoresSafeArea()
                .opacity(started ? 1 : 0.3)
                .overlay(
                    Color.black.opacity(started ? 0 : 0.4)
                        .allowsHitTesting(false)
                )

            VStack {
                if !started {
                    Spacer()
                    startCard
                        .padding(.bottom, 60)
                } else {
                    Spacer()
                    countingSummary
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        .task {
            let status = await container.cameraService.checkPermission()
            if status == .notDetermined {
                _ = await container.cameraService.requestPermission()
            }
            if container.cameraService.status == .ready || container.cameraService.status == .running {
                await container.cameraService.configure()
            }
        }
        .onDisappear {
            container.cameraService.stop()
        }
        .sheet(item: $manualAdjustDenomination) { denomination in
            ManualAdjustSheet(
                denomination: denomination,
                currentCount: manualAdjustCount,
                onSet: { newValue in
                    container.countingService.setCount(newValue, for: denomination)
                    manualAdjustDenomination = nil
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.regularMaterial)
        }
        .sheet(isPresented: $showCompletionSheet) {
            CompletionSheet(
                total: container.countingService.totalAmount,
                count: container.countingService.totalCount,
                items: container.countingService.counted,
                onClose: {
                    showCompletionSheet = false
                    started = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.regularMaterial)
        }
    }

    private var startCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.app.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 8) {
                Text("Режим пересчёта")
                    .font(.title.bold())
                Text("Наведите камеру на банкноты по очереди.\nCashVision распознает и посчитает сумму.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            Button {
                container.countingService.startCounting()
                container.cameraService.start()
                withAnimation(.cashSpring) {
                    started = true
                }
                container.analytics.track(.init(name: .countingStarted))
            } label: {
                Label("Начать пересчёт", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
        }
        .foregroundStyle(.white)
        .padding(28)
        .adaptiveGlassBackground(cornerRadius: 24)
        .padding(.horizontal, 16)
    }

    private var countingSummary: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ИТОГО")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(formattedAmount)
                        .font(.title.bold())
                        .contentTransition(.numericText())
                        .animation(.cashSpring, value: container.countingService.totalAmount)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("КУПЮР")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("\(container.countingService.totalCount)")
                        .font(.title2.bold())
                        .contentTransition(.numericText())
                        .animation(.cashSpring, value: container.countingService.totalCount)
                }
            }

            Divider()
                .background(.white.opacity(0.15))

            if container.countingService.counted.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "viewfinder")
                        .foregroundStyle(.secondary)
                    Text("Пока ничего не распознано")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(
                        container.countingService.counted.sorted(by: { $0.key.value > $1.key.value }),
                        id: \.key
                    ) { denom, count in
                        HStack {
                            Text(denom.formatted)
                                .font(.body)
                            Spacer()
                            Text("×\(count)")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Button {
                                manualAdjustDenomination = denom
                                manualAdjustCount = count
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.cashSpring, value: container.countingService.counted)
            }

            HStack(spacing: 12) {
                Button {
                    container.countingService.clear()
                } label: {
                    Label("Очистить", systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button {
                    container.countingService.stopCounting()
                    container.history.save(
                        counted: container.countingService.counted,
                        total: container.countingService.totalAmount,
                        totalCount: container.countingService.totalCount,
                        mode: "count"
                    )
                    container.analytics.track(.init(
                        name: .countingCompleted,
                        properties: ["total": String(container.countingService.totalAmount)]
                    ))
                    showCompletionSheet = true
                } label: {
                    Label("Завершить", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .adaptiveGlassBackground(cornerRadius: 20)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let value = NSNumber(value: container.countingService.totalAmount)
        return (formatter.string(from: value) ?? "\(container.countingService.totalAmount)") + " ₽"
    }
}

struct ManualAdjustSheet: View {
    let denomination: Denomination
    let currentCount: Int
    let onSet: (Int) -> Void
    @State private var value: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(denomination.formatted)
                        .font(.largeTitle.bold())
                    Text("Укажите количество вручную")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Stepper(value: $value, in: 0...1_000) {
                    Text("\(value) шт.")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.cashSpring, value: value)
                }
                .padding(.horizontal, 24)

                Spacer()
                Button {
                    onSet(value)
                } label: {
                    Text("Сохранить")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Корректировка")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { value = currentCount }
        }
    }
}

struct CompletionSheet: View {
    let total: Int
    let count: Int
    let items: [Denomination: Int]
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))

                    Text("Пересчёт завершён")
                        .font(.title2.bold())
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Сумма")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formattedAmount)
                            .font(.title.bold())
                    }
                    HStack {
                        Text("Купюр")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(count)")
                            .font(.title2.bold())
                    }

                    Divider()

                    ForEach(items.sorted(by: { $0.key.value > $1.key.value }), id: \.key) { denom, cnt in
                        HStack {
                            Text(denom.formatted)
                            Spacer()
                            Text("×\(cnt)")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))

                Spacer()
                Button {
                    onClose()
                } label: {
                    Text("Готово")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Результат")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return (formatter.string(from: NSNumber(value: total)) ?? "\(total)") + " ₽"
    }
}
