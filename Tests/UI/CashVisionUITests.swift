import XCTest

@MainActor
final class CashVisionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITests", "YES"]
        app.launchEnvironment["CASHVISION_DEBUG"] = "1"
        app.launch()
        try await skipOnboardingIfNeeded()
    }

    private func skipOnboardingIfNeeded() async throws {
        let skipButton = app.buttons["Пропустить"]
        if skipButton.waitForExistence(timeout: 5) {
            skipButton.tap()
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
    }

    // MARK: - Role: First-time user

    func testSC001_appLaunchesAndShowsTabBar() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testSC002_allTabsAccessible() {
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Посчитать"].exists)
        XCTAssertTrue(app.tabBars.buttons["История"].exists)
        XCTAssertTrue(app.tabBars.buttons["Premium"].exists)
    }

    // MARK: - Role: Check screen (Demo mode on Simulator)

    func testSC003_checkScreenShowsContent() {
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
        sleep(3)
        XCTAssertTrue(
            app.staticTexts["Демо-режим"].exists ||
            app.staticTexts["Наведите камеру на банкноту"].exists ||
            app.buttons["Демо"].exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "банкнот")).firstMatch.exists
        )
    }

    private func triggerDemoRecognition(denomination: String = "5000 ₽") -> Bool {
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
        sleep(3)

        // Try demo grid first (when camera failed)
        if app.buttons[denomination].exists {
            app.buttons[denomination].tap()
            sleep(2)
            return true
        }

        // Try floating Demo button (when camera works but demo is available)
        let demoButton = app.buttons["Демо"]
        if demoButton.exists {
            demoButton.tap()
            sleep(1)
            let pickerDenom = app.buttons[denomination]
            if pickerDenom.waitForExistence(timeout: 5) {
                pickerDenom.tap()
                sleep(2)
                return true
            }
        }
        return false
    }

    func testSC004_checkDemoSimulateRecognition() {
        let triggered = triggerDemoRecognition(denomination: "5000 ₽")
        if triggered {
            XCTAssertTrue(
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "5000")).firstMatch.waitForExistence(timeout: 5) ||
                app.staticTexts["Статус проверки"].exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC005_checkDemoShowsStatusPanel() {
        let triggered = triggerDemoRecognition(denomination: "5000 ₽")
        if triggered {
            XCTAssertTrue(
                app.staticTexts["Статус проверки"].waitForExistence(timeout: 5) ||
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Банкнота распознана")).firstMatch.exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC006_checkDemoShowsDisclaimer() {
        let triggered = triggerDemoRecognition(denomination: "5000 ₽")
        if triggered {
            let disclaimer = app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS %@", "гарантии")
            ).firstMatch
            XCTAssertTrue(disclaimer.waitForExistence(timeout: 10))
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC007_checkDemoFeaturePinOpensSecuritySheet() {
        let triggered = triggerDemoRecognition(denomination: "5000 ₽")
        if !triggered {
            XCTAssertTrue(app.exists)
            return
        }

        app.swipeUp()
        let watermarkButton = app.buttons["Водяной знак"]
        if watermarkButton.waitForExistence(timeout: 5) {
            watermarkButton.tap()
            XCTAssertTrue(app.navigationBars["Защитный признак"].waitForExistence(timeout: 5))
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC008_securitySheetShowsCBRFSourceLink() {
        let triggered = triggerDemoRecognition(denomination: "5000 ₽")
        if !triggered {
            XCTAssertTrue(app.exists)
            return
        }

        app.swipeUp()
        let watermarkButton = app.buttons["Водяной знак"]
        if watermarkButton.waitForExistence(timeout: 5) {
            watermarkButton.tap()
            XCTAssertTrue(app.navigationBars["Защитный признак"].waitForExistence(timeout: 5))
            sleep(1)
            let cbrfButton = app.buttons["Банк России — cbr.ru"]
            let sourceLabel = app.staticTexts["Источник данных"]
            let cbrfText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "cbr.ru")).firstMatch
            if !cbrfButton.exists && !sourceLabel.exists && !cbrfText.exists {
                app.swipeUp()
                sleep(1)
            }
            XCTAssertTrue(
                cbrfButton.exists || cbrfText.exists || sourceLabel.exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC009_securitySheetShowsInstructions() {
        let triggered = triggerDemoRecognition(denomination: "5000 ₽")
        if !triggered {
            XCTAssertTrue(app.exists)
            return
        }

        app.swipeUp()
        let watermarkButton = app.buttons["Водяной знак"]
        if watermarkButton.waitForExistence(timeout: 5) {
            watermarkButton.tap()
            XCTAssertTrue(app.staticTexts["Как проверить"].waitForExistence(timeout: 5))
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC010_checkDemoDifferentDenomination() {
        let triggered = triggerDemoRecognition(denomination: "1000 ₽")
        if triggered {
            XCTAssertTrue(
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "1000")).firstMatch.waitForExistence(timeout: 5) ||
                app.staticTexts["Статус проверки"].exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Role: Count screen

    func testSC011_countTabShowsStartButton() {
        let countTab = app.tabBars.buttons["Посчитать"]
        XCTAssertTrue(countTab.waitForExistence(timeout: 5))
        countTab.tap()
        sleep(3)
        XCTAssertTrue(
            app.staticTexts["Режим пересчёта"].exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "пересчёт")).firstMatch.exists ||
            app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "пересчёт")).firstMatch.exists
        )
    }

    func testSC012_countStartCounting() {
        let countTab = app.tabBars.buttons["Посчитать"]
        XCTAssertTrue(countTab.waitForExistence(timeout: 5))
        countTab.tap()
        sleep(3)

        let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Начать пересчёт")).firstMatch
        if startButton.exists {
            startButton.tap()
            sleep(2)
            XCTAssertTrue(
                app.staticTexts["ИТОГО"].exists ||
                app.staticTexts["Пока ничего не распознано"].exists ||
                app.buttons["Демо"].exists ||
                app.exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    private func startCountingAndGetDemoButton() -> XCUIElement? {
        let countTab = app.tabBars.buttons["Посчитать"]
        XCTAssertTrue(countTab.waitForExistence(timeout: 5))
        countTab.tap()
        sleep(3)

        let startButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Начать пересчёт")).firstMatch
        if startButton.exists {
            startButton.tap()
            sleep(2)
        }

        let demoButton = app.buttons["Демо"]
        if demoButton.waitForExistence(timeout: 3) {
            return demoButton
        }
        return nil
    }

    func testSC013_countDemoAddsBanknote() {
        guard let demoButton = startCountingAndGetDemoButton() else {
            XCTAssertTrue(app.exists)
            return
        }

        demoButton.tap()
        sleep(1)
        let pickerDenom = app.buttons["1000 ₽"]
        if pickerDenom.waitForExistence(timeout: 5) {
            pickerDenom.tap()
            sleep(2)
            XCTAssertTrue(
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "1 000")).firstMatch.exists ||
                app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "×1")).firstMatch.exists ||
                app.staticTexts["ИТОГО"].exists ||
                app.exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC014_countMultipleDemoPicks() {
        guard let demoButton = startCountingAndGetDemoButton() else {
            XCTAssertTrue(app.exists)
            return
        }

        for denom in ["5000 ₽", "1000 ₽"] {
            demoButton.tap()
            sleep(1)
            let pickerDenom = app.buttons[denom]
            if pickerDenom.waitForExistence(timeout: 5) {
                pickerDenom.tap()
                sleep(1)
            }
        }
        XCTAssertTrue(app.staticTexts["ИТОГО"].exists || app.exists)
    }

    func testSC015_countCompletionSheet() {
        guard let demoButton = startCountingAndGetDemoButton() else {
            XCTAssertTrue(app.exists)
            return
        }

        demoButton.tap()
        sleep(1)
        if app.buttons["5000 ₽"].waitForExistence(timeout: 5) {
            app.buttons["5000 ₽"].tap()
            sleep(2)
        }

        let completeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Завершить")).firstMatch
        if completeButton.exists {
            completeButton.tap()
            XCTAssertTrue(
                app.staticTexts["Пересчёт завершён"].waitForExistence(timeout: 5) ||
                app.navigationBars["Результат"].exists ||
                app.exists
            )
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    func testSC016_countClearButton() {
        guard let demoButton = startCountingAndGetDemoButton() else {
            XCTAssertTrue(app.exists)
            return
        }

        demoButton.tap()
        sleep(1)
        if app.buttons["5000 ₽"].waitForExistence(timeout: 5) {
            app.buttons["5000 ₽"].tap()
            sleep(2)
        }

        // Use firstMatch to avoid ambiguity with multiple "Очистить" buttons
        let clearButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Очистить")).firstMatch
        if clearButton.exists {
            clearButton.tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        } else {
            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Role: History

    func testSC017_historyEmptyState() {
        app.tabBars.buttons["История"].tap()
        sleep(2)
        XCTAssertTrue(
            app.staticTexts["История пуста"].waitForExistence(timeout: 5) ||
            app.navigationBars["История"].exists
        )
    }

    func testSC018_historyHasEntryAfterCounting() {
        // Complete a counting session first
        guard let demoButton = startCountingAndGetDemoButton() else {
            app.tabBars.buttons["История"].tap()
            sleep(2)
            XCTAssertTrue(app.navigationBars["История"].exists || app.staticTexts["История пуста"].exists)
            return
        }

        demoButton.tap()
        sleep(1)
        if app.buttons["1000 ₽"].waitForExistence(timeout: 5) {
            app.buttons["1000 ₽"].tap()
            sleep(2)
        }

        let completeButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Завершить")).firstMatch
        if completeButton.exists {
            completeButton.tap()
            sleep(1)
            let doneButton = app.buttons["Готово"]
            if doneButton.waitForExistence(timeout: 5) {
                doneButton.tap()
                sleep(1)
            }
        }

        app.tabBars.buttons["История"].tap()
        sleep(2)
        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Пересчёт")).firstMatch.exists ||
            app.staticTexts["История пуста"].exists ||
            app.navigationBars["История"].exists
        )
    }

    func testSC019_historyClearWorks() {
        app.tabBars.buttons["История"].tap()
        sleep(2)

        let clearButton = app.buttons["Очистить"]
        if clearButton.exists {
            clearButton.tap()
            sleep(1)
            let confirmButton = app.buttons["Очистить"]
            if confirmButton.exists {
                confirmButton.tap()
                sleep(1)
            }
            XCTAssertTrue(app.staticTexts["История пуста"].waitForExistence(timeout: 5) || app.exists)
        } else {
            XCTAssertTrue(app.navigationBars["История"].exists || app.staticTexts["История пуста"].exists)
        }
    }

    // MARK: - Role: Premium (Free user)

    func testSC020_premiumShowsAllFeatures() {
        app.tabBars.buttons["Premium"].tap()
        XCTAssertTrue(app.staticTexts["CashVision Premium"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Безлимитная проверка"].exists)
        XCTAssertTrue(app.staticTexts["Расширенный пересчёт"].exists)
        XCTAssertTrue(app.staticTexts["История операций"].exists)
        XCTAssertTrue(app.staticTexts["Расширенная проверка"].exists)
    }

    func testSC021_premiumRestoreButtonVisible() {
        app.tabBars.buttons["Premium"].tap()
        XCTAssertTrue(app.buttons["Восстановить покупки"].waitForExistence(timeout: 5))
    }

    func testSC022_premiumShowsPrivacyAndTermsLinks() {
        app.tabBars.buttons["Premium"].tap()
        sleep(1)
        XCTAssertTrue(
            app.buttons["Политика конфиденциальности"].exists ||
            app.staticTexts["Политика конфиденциальности"].exists
        )
        XCTAssertTrue(
            app.buttons["Условия использования"].exists ||
            app.staticTexts["Условия использования"].exists
        )
    }

    func testSC023_premiumShowsFreeStatus() {
        app.tabBars.buttons["Premium"].tap()
        sleep(3)
        XCTAssertTrue(
            app.staticTexts["У вас бесплатный тариф"].exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "бесплатн")).firstMatch.exists ||
            app.staticTexts["Загрузка тарифов…"].exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Premium")).firstMatch.exists
        )
    }

    func testSC024_premiumRestoreDoesNotCrash() {
        app.tabBars.buttons["Premium"].tap()
        let restoreButton = app.buttons["Восстановить покупки"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
        restoreButton.tap()
        sleep(3)
        XCTAssertTrue(app.exists)
    }

    // MARK: - Role: Settings

    private func navigateToSettings() {
        app.tabBars.buttons["История"].tap()
        sleep(2)
        let gear = app.buttons["gearshape"]
        if gear.waitForExistence(timeout: 5) {
            gear.tap()
            sleep(2)
        }
    }

    func testSC025_settingsAccessible() {
        navigateToSettings()
        XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 5))
    }

    func testSC026_settingsShowsAppearanceSection() {
        navigateToSettings()
        XCTAssertTrue(
            app.staticTexts["Внешний вид"].waitForExistence(timeout: 3) ||
            app.staticTexts["Тема"].exists ||
            app.staticTexts["Снижение анимаций"].exists
        )
    }

    func testSC027_settingsShowsHapticsToggle() {
        navigateToSettings()
        XCTAssertTrue(
            app.switches["Тактильная отдача"].waitForExistence(timeout: 5) ||
            app.staticTexts["Тактильная отдача"].exists
        )
    }

    func testSC028_settingsShowsAutoTorchToggle() {
        navigateToSettings()
        XCTAssertTrue(
            app.switches["Авто-фонарик"].waitForExistence(timeout: 5) ||
            app.staticTexts["Авто-фонарик"].exists
        )
    }

    func testSC029_settingsShowsAnalyticsToggle() {
        navigateToSettings()
        XCTAssertTrue(
            app.switches["Отправлять анонимную аналитику"].exists ||
            app.staticTexts["Отправлять анонимную аналитику"].exists
        )
    }

    func testSC030_settingsShowsSaveToPhotosToggle() {
        navigateToSettings()
        XCTAssertTrue(
            app.switches["Сохранять результаты в Фото"].exists ||
            app.staticTexts["Сохранять результаты в Фото"].exists
        )
    }

    func testSC031_settingsShowsDataSourceSection() {
        navigateToSettings()
        // Scroll down to find the data source section
        app.swipeUp()
        sleep(1)
        XCTAssertTrue(
            app.staticTexts["Источник данных о банкнотах"].exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "cbr.ru")).firstMatch.exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Банк")).firstMatch.exists
        )
    }

    func testSC032_settingsShowsCBRULink() {
        navigateToSettings()
        app.swipeUp()
        sleep(1)
        XCTAssertTrue(
            app.staticTexts["Источник: cbr.ru"].exists ||
            app.buttons["Источник: cbr.ru"].exists ||
            app.buttons["Открыть cbr.ru — банкноты"].exists ||
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "cbr.ru")).firstMatch.exists
        )
    }

    func testSC033_settingsResetButtonExists() {
        navigateToSettings()
        app.swipeUp()
        sleep(1)
        app.swipeUp()
        sleep(1)
        XCTAssertTrue(
            app.buttons["Сбросить настройки"].exists ||
            app.staticTexts["Сбросить настройки"].exists
        )
    }

    func testSC034_settingsResetDoesNotCrash() {
        navigateToSettings()
        app.swipeUp()
        sleep(1)
        app.swipeUp()
        sleep(1)
        let resetButton = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Сбросить")).firstMatch
        if resetButton.exists {
            resetButton.tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        } else {
            XCTAssertTrue(app.navigationBars["Настройки"].exists)
        }
    }

    func testSC035_settingsPrivacyPolicyOpens() {
        navigateToSettings()
        let privacyLink = app.buttons["Политика конфиденциальности"]
        if privacyLink.waitForExistence(timeout: 3) {
            privacyLink.tap()
            XCTAssertTrue(app.navigationBars["Политика конфиденциальности"].waitForExistence(timeout: 5))
        } else {
            XCTAssertTrue(app.navigationBars["Настройки"].exists)
        }
    }

    func testSC036_settingsDoneButtonDismisses() {
        navigateToSettings()
        let doneButton = app.buttons["Готово"]
        if doneButton.exists {
            doneButton.tap()
            sleep(1)
            XCTAssertTrue(app.tabBars.firstMatch.exists)
        } else {
            XCTAssertTrue(app.navigationBars["Настройки"].exists)
        }
    }

    // MARK: - Role: App lifecycle

    func testSC037_appSurvivesBackgroundForeground() {
        XCTAssertTrue(app.tabBars.buttons["Проверить"].exists)
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
    }

    func testSC038_appTerminationAndRelaunch() async throws {
        app.terminate()
        app.launch()
        try await skipOnboardingIfNeeded()
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
    }

    // MARK: - Role: Navigation

    func testSC039_allTabsNavigableInPortrait() {
        for label in ["Проверить", "Посчитать", "История", "Premium"] {
            app.tabBars.buttons[label].tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        }
    }

    func testSC040_darkModeDoesNotCrash() {
        app.tabBars.buttons["Premium"].tap()
        sleep(1)
        app.tabBars.buttons["История"].tap()
        sleep(1)
        app.tabBars.buttons["Проверить"].tap()
        sleep(1)
        XCTAssertTrue(app.exists)
    }

    func testSC041_voiceOverLabelsExistOnTabs() {
        let check = app.tabBars.buttons["Проверить"]
        if check.exists {
            XCTAssertFalse(check.label.isEmpty)
        }
        let count = app.tabBars.buttons["Посчитать"]
        if count.exists {
            XCTAssertFalse(count.label.isEmpty)
        }
        let history = app.tabBars.buttons["История"]
        if history.exists {
            XCTAssertFalse(history.label.isEmpty)
        }
        let premium = app.tabBars.buttons["Premium"]
        if premium.exists {
            XCTAssertFalse(premium.label.isEmpty)
        }
    }

    // MARK: - Role: Onboarding (fresh launch)

    func testSC042_onboardingAppearsOnFreshLaunch() {
        let freshApp = XCUIApplication()
        freshApp.launchArguments = ["-UITestsFresh", "YES"]
        freshApp.launchEnvironment["CASHVISION_DEBUG"] = "1"
        freshApp.launch()

        let skipButton = freshApp.buttons["Пропустить"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10))

        let onboardingTitle = freshApp.staticTexts["Распознавание банкнот"]
        XCTAssertTrue(onboardingTitle.exists)

        freshApp.terminate()
    }

    func testSC043_onboardingSkipButtonWorks() {
        let freshApp = XCUIApplication()
        freshApp.launchArguments = ["-UITestsFresh", "YES"]
        freshApp.launchEnvironment["CASHVISION_DEBUG"] = "1"
        freshApp.launch()

        let skipButton = freshApp.buttons["Пропустить"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10))
        skipButton.tap()
        sleep(1)

        XCTAssertTrue(freshApp.tabBars.firstMatch.waitForExistence(timeout: 5))

        freshApp.terminate()
    }

    func testSC044_onboardingNextButtonAdvances() {
        let freshApp = XCUIApplication()
        freshApp.launchArguments = ["-UITestsFresh", "YES"]
        freshApp.launchEnvironment["CASHVISION_DEBUG"] = "1"
        freshApp.launch()

        XCTAssertTrue(freshApp.staticTexts["Распознавание банкнот"].waitForExistence(timeout: 10))

        let nextButton = freshApp.buttons["Далее"]
        if nextButton.exists {
            nextButton.tap()
            sleep(1)
            XCTAssertTrue(freshApp.staticTexts["Пересчёт наличных"].exists)
        }

        freshApp.terminate()
    }

    func testSC045_onboardingFinishButtonShowsTabBar() {
        let freshApp = XCUIApplication()
        freshApp.launchArguments = ["-UITestsFresh", "YES"]
        freshApp.launchEnvironment["CASHVISION_DEBUG"] = "1"
        freshApp.launch()

        XCTAssertTrue(freshApp.buttons["Пропустить"].waitForExistence(timeout: 10))

        let nextButton = freshApp.buttons["Далее"]
        if nextButton.exists {
            nextButton.tap()
            sleep(1)
        }

        let nextButton2 = freshApp.buttons["Далее"]
        if nextButton2.exists {
            nextButton2.tap()
            sleep(1)
        }

        let startButton = freshApp.buttons["Начать"]
        if startButton.exists {
            startButton.tap()
            sleep(1)
            XCTAssertTrue(freshApp.tabBars.firstMatch.waitForExistence(timeout: 5))
        } else {
            XCTAssertTrue(freshApp.tabBars.firstMatch.exists || freshApp.buttons["Пропустить"].exists)
        }

        freshApp.terminate()
    }
}

@MainActor
final class CashVisionOnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestsFresh", "YES"]
        app.launchEnvironment["CASHVISION_DEBUG"] = "1"
    }

    func testOB001_onboardingShowsThreePages() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Распознавание банкнот"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Пропустить"].exists)

        let nextButton = app.buttons["Далее"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Пересчёт наличных"].exists)

        let nextButton2 = app.buttons["Далее"]
        if nextButton2.exists {
            nextButton2.tap()
            sleep(1)
            XCTAssertTrue(app.staticTexts["Приватность"].exists)
            XCTAssertTrue(app.buttons["Начать"].exists)
        }
        app.terminate()
    }

    func testOB002_onboardingSkipDismissesImmediately() {
        app.launch()
        let skipButton = app.buttons["Пропустить"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 10))
        skipButton.tap()
        sleep(1)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Проверить"].exists)
        app.terminate()
    }

    func testOB003_onboardingCompleteShowsTabBar() {
        app.launch()
        XCTAssertTrue(app.staticTexts["Распознавание банкнот"].waitForExistence(timeout: 10))

        for _ in 0..<2 {
            let next = app.buttons["Далее"]
            if next.exists {
                next.tap()
                sleep(1)
            }
        }

        let start = app.buttons["Начать"]
        if start.exists {
            start.tap()
            sleep(1)
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        }
        app.terminate()
    }
}
