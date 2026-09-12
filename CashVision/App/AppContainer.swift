import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    let logger: AppLogger.Type
    let configuration: AppConfiguration
    let banknoteRepository: BanknoteRepository
    let banknoteDataProvider: BanknoteDataProvider
    let serialVerificationProvider: BanknoteSerialVerificationProvider
    let historyRepository: HistoryRepository
    let history: HistoryViewModel
    let subscription: SubscriptionManager
    let settings: SettingsStore
    let analytics: AnalyticsService
    let cameraService: CameraService
    let recognitionService: BanknoteRecognitionService
    let countingService: CountingService
    let apiClient: APIClient
    let security: SecurityService

    init() {
        let config = AppConfiguration.load()
        self.configuration = config
        self.logger = AppLogger.self

        let localProvider = LocalBanknoteDataProvider()
        self.banknoteDataProvider = CompositeBanknoteDataProvider(
            local: localProvider,
            remote: RemoteBanknoteDataProvider(apiClient: APIClient(baseURL: config.apiBaseURL))
        )
        self.banknoteRepository = BanknoteRepository(provider: banknoteDataProvider)
        self.serialVerificationProvider = CompositeSerialVerificationProvider()
        self.historyRepository = HistoryRepository()
        self.history = HistoryViewModel(repository: historyRepository)
        self.subscription = SubscriptionManager(productIDs: config.productIDs)
        self.settings = SettingsStore()
        self.analytics = AnalyticsService()
        self.cameraService = CameraService()
        self.recognitionService = BanknoteRecognitionService(banknoteRepository: banknoteRepository)
        self.countingService = CountingService(recognition: recognitionService)
        self.apiClient = APIClient(baseURL: config.apiBaseURL)
        self.security = SecurityService()
    }
}
