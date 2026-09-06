import SwiftUI
import AVFoundation
import Observation

struct CountView: View {
    let container: AppContainer
    @State private var started = false
    @State private var manualAdjustDenomination: Denomination?
    @State private var manualAdjustCount: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: container.cameraService.captureSession)
                .ignoresSafeArea()
                .opacity(started ? 1 : 0.4)

            VStack {
                if !started {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("Режим пересчёта")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("Наведите камеру на банкноты по очереди. CashVision их распознает и посчитает сумму.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                        Button("Начать пересчёт") {
                            container.countingService.startCounting()
                            container.cameraService.start()
                            started = true
                            container.analytics.track(.init(name: .countingStarted))
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 60)
                } else {
                    Spacer()
                    countingSummary
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }

            if started {
                BanknoteOverlayView(recognized: []) { _, _ in }
                    .allowsHitTesting(false)
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
        }
    }

    private var countingSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("ИТОГО")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formattedAmount)
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }

            Divider().background(.white.opacity(0.3))

            if container.countingService.counted.isEmpty {
                Text("Пока ничего не распознано")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ForEach(container.countingService.counted.sorted(by: { $0.key.value > $1.key.value }), id: \.key) { denom, count in
                    HStack {
                        Text(denom.formatted)
                        Spacer()
                        Text("×\(count)")
                            .foregroundStyle(.secondary)
                        Button {
                            manualAdjustDenomination = denom
                            manualAdjustCount = count
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                    .foregroundStyle(.white)
                    .font(.body)
                }
            }

            HStack {
                Button("Очистить") {
                    container.countingService.clear()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                Spacer()
                Button("Завершить") {
                    container.countingService.stopCounting()
                    container.history.save(
                        counted: container.countingService.counted,
                        total: container.countingService.totalAmount,
                        totalCount: container.countingService.totalCount,
                        mode: "count"
                    )
                    container.analytics.track(.init(name: .countingCompleted, properties: ["total": String(container.countingService.totalAmount)]))
                    started = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            VStack(spacing: 20) {
                Text(denomination.formatted).font(.title2.bold())
                Stepper(value: $value, in: 0...1_000) {
                    Text("\(value) шт.")
                        .font(.title)
                        .monospacedDigit()
                }
                Spacer()
                Button("Сохранить") { onSet(value) }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.bottom)
            }
            .padding()
            .navigationTitle("Корректировка")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { value = currentCount }
        }
    }
}
