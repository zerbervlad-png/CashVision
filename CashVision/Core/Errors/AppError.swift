import Foundation

enum AppError: LocalizedError {
    case cameraUnavailable
    case cameraPermissionDenied
    case recognitionFailed
    case insufficientLight
    case banknotePartiallyObscured
    case banknoteTooFar
    case networkUnavailable
    case serverError(Int)
    case decodingFailed
    case subscriptionFailed
    case serialVerificationUnavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Камера недоступна на этом устройстве"
        case .cameraPermissionDenied:
            return "Доступ к камере запрещён. Откройте Настройки, чтобы включить доступ."
        case .recognitionFailed:
            return "Не удалось распознать банкноту"
        case .insufficientLight:
            return "Недостаточно света"
        case .banknotePartiallyObscured:
            return "Банкнота частично закрыта"
        case .banknoteTooFar:
            return "Попробуйте переместить камеру ближе"
        case .networkUnavailable:
            return "Проверьте интернет-соединение"
        case .serverError(let code):
            return "Ошибка сервера (\(code))"
        case .decodingFailed:
            return "Не удалось обработать ответ сервера"
        case .subscriptionFailed:
            return "Не удалось завершить покупку"
        case .serialVerificationUnavailable:
            return "Проверка по внешней базе недоступна"
        case .unknown:
            return "Произошла неизвестная ошибка"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Откройте Настройки → CashVision → Камера"
        case .insufficientLight:
            return "Переместитесь в более светлое место"
        case .banknotePartiallyObscured:
            return "Уберите предметы, перекрывающие банкноту"
        case .banknoteTooFar:
            return "Поднесите камеру ближе к банкноте"
        default:
            return nil
        }
    }
}
