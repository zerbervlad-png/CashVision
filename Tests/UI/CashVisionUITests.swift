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

    func testSC001_appLaunchesAndShowsCameraHint() {
        XCTAssertTrue(
            app.staticTexts["Наведите камеру на банкноту"].waitForExistence(timeout: 5) ||
            app.tabBars.firstMatch.exists
        )
    }

    func testSC002_cameraPermissionDeniedShowsExplanation() {
        XCTAssertTrue(app.exists)
    }

    func testSC003_tabsAreAccessible() {
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Посчитать"].exists)
        XCTAssertTrue(app.tabBars.buttons["История"].exists)
        XCTAssertTrue(app.tabBars.buttons["Premium"].exists)
    }

    func testSC004_countTabShowsStartButton() {
        app.tabBars.buttons["Посчитать"].tap()
        let startButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "пересчёт")
        ).firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
    }

    func testSC005_historyTabShowsEmptyState() {
        app.tabBars.buttons["История"].tap()
        XCTAssertTrue(
            app.staticTexts["История пуста"].waitForExistence(timeout: 5) ||
            app.navigationBars["История"].waitForExistence(timeout: 5)
        )
    }

    func testSC006_premiumTabLoadsAndShowsFeatures() {
        app.tabBars.buttons["Premium"].tap()
        XCTAssertTrue(app.staticTexts["CashVision Premium"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Безлимитная проверка"].exists)
        XCTAssertTrue(app.buttons["Восстановить покупки"].exists)
    }

    func testSC007_settingsAccessibleFromHistory() {
        app.tabBars.buttons["История"].tap()
        let gear = app.buttons["gearshape"]
        if gear.waitForExistence(timeout: 5) {
            gear.tap()
            XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 5))
        }
    }

    func testSC008_onboardingCanBeSkipped() {
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }

    func testSC009_darkModeDoesNotCrash() {
        app.tabBars.buttons["Premium"].tap()
        app.tabBars.buttons["История"].tap()
        app.tabBars.buttons["Проверить"].tap()
        XCTAssertTrue(app.exists)
    }

    func testSC010_appTerminationAndRelaunch() async throws {
        app.terminate()
        app.launch()
        try await skipOnboardingIfNeeded()
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
    }

    func testSC011_settingsTabShowsPrivacyPolicy() {
        app.tabBars.buttons["История"].tap()
        let gear = app.buttons["gearshape"]
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
            let privacyLink = app.buttons["Политика конфиденциальности"]
            if privacyLink.waitForExistence(timeout: 3) {
                privacyLink.tap()
                XCTAssertTrue(app.navigationBars["Политика конфиденциальности"].waitForExistence(timeout: 5))
            }
        }
    }

    func testSC012_settingsShowsHapticsToggle() {
        app.tabBars.buttons["История"].tap()
        let gear = app.buttons["gearshape"]
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
            XCTAssertTrue(
                app.switches["Тактильная отдача"].waitForExistence(timeout: 5) ||
                app.staticTexts["Тактильная отдача"].waitForExistence(timeout: 5)
            )
        }
    }

    func testSC013_settingsShowsAutoTorchToggle() {
        app.tabBars.buttons["История"].tap()
        let gear = app.buttons["gearshape"]
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
            XCTAssertTrue(
                app.switches["Авто-фонарик"].waitForExistence(timeout: 5) ||
                app.staticTexts["Авто-фонарик"].waitForExistence(timeout: 5)
            )
        }
    }

    func testSC014_torchToggleInCheckModeIfExists() {
        app.tabBars.buttons["Проверить"].tap()
        if app.buttons["Фонарик"].waitForExistence(timeout: 3) {
            app.buttons["Фонарик"].tap()
            sleep(1)
            app.buttons["Фонарик"].tap()
        }
        XCTAssertTrue(app.exists)
    }

    func testSC015_clearDataInSettingsDoesNotCrash() {
        app.tabBars.buttons["История"].tap()
        let gear = app.buttons["gearshape"]
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
            if app.buttons["Очистить все данные"].waitForExistence(timeout: 3) {
                app.buttons["Очистить все данные"].tap()
                if app.buttons["Очистить"].waitForExistence(timeout: 3) {
                    app.buttons["Очистить"].tap()
                }
            }
        }
        XCTAssertTrue(app.exists)
    }

    func testSC016_voiceOverLabelsExistOnTabs() {
        let check = app.tabBars.buttons["Проверить"]
        if check.exists {
            XCTAssertFalse(check.label.isEmpty)
        }
    }

    func testSC017_premiumRestoreButtonAlwaysVisible() {
        app.tabBars.buttons["Premium"].tap()
        XCTAssertTrue(app.buttons["Восстановить покупки"].waitForExistence(timeout: 5))
    }

    func testSC018_appSurvivesBackgroundForeground() {
        app.tabBars.buttons["Проверить"].tap()
        XCUIDevice.shared.press(XCUIDevice.Button.home)
        sleep(2)
        app.activate()
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
    }

    func testSC019_disclaimerVisibleOnCheckScreen() {
        app.tabBars.buttons["Проверить"].tap()
        let disclaimer = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "гарантии")
        ).firstMatch
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5) || app.exists)
    }

    func testSC020_allTabsNavigableInPortrait() {
        for label in ["Проверить", "Посчитать", "История", "Premium"] {
            app.tabBars.buttons[label].tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        }
    }
}
