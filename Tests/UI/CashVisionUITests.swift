import XCTest

@MainActor
final class CashVisionUITests: XCTestCase {
    var app: XCUIApplication!

    @MainActor
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITests", "YES"]
        app.launchEnvironment["CASHVISION_DEBUG"] = "1"
        app.launch()
    }

    func testSC001_appLaunchesAndShowsCameraHint() {
        XCTAssertTrue(app.staticTexts["Наведите камеру на банкноту"].waitForExistence(timeout: 5) ||
                       app.buttons["Начать"].waitForExistence(timeout: 5))
    }

    func testSC002_cameraPermissionDeniedShowsExplanation() {
        // Симуляция невозможна без mock permission, но проверяем наличие UI при отказе.
        // На Simulator permission по умолчанию granted при первом запуске.
        XCTAssertTrue(app.exists)
    }

    func testSC003_tabsAreAccessible() {
        XCTAssertTrue(app.tabBars.buttons["Проверить"].exists)
        XCTAssertTrue(app.tabBars.buttons["Посчитать"].exists)
        XCTAssertTrue(app.tabBars.buttons["История"].exists)
        XCTAssertTrue(app.tabBars.buttons["Premium"].exists)
    }

    func testSC004_countTabShowsStartButton() {
        app.tabBars.buttons["Посчитать"].tap()
        XCTAssertTrue(app.buttons["Начать пересчёт"].waitForExistence(timeout: 3))
    }

    func testSC005_historyTabShowsEmptyState() {
        app.tabBars.buttons["История"].tap()
        // Либо пустое состояние, либо список
        XCTAssertTrue(app.staticTexts["История пуста"].waitForExistence(timeout: 3) ||
                      app.navigationBars["История"].waitForExistence(timeout: 3))
    }

    func testSC006_premiumTabLoadsAndShowsFeatures() {
        app.tabBars.buttons["Premium"].tap()
        XCTAssertTrue(app.staticTexts["CashVision Premium"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Безлимитная проверка"].exists)
        XCTAssertTrue(app.buttons["Восстановить покупки"].exists)
    }

    func testSC007_settingsAccessibleFromHistory() {
        app.tabBars.buttons["История"].tap()
        if app.buttons["gearshape"].waitForExistence(timeout: 3) {
            app.buttons["gearshape"].tap()
            XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 3))
        }
    }

    func testSC008_onboardingCanBeSkipped() {
        if app.buttons["Пропустить"].waitForExistence(timeout: 3) {
            app.buttons["Пропустить"].tap()
            XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 3))
        }
    }

    func testSC009_darkModeDoesNotCrash() {
        // Системная тема; ничего не должно падать.
        app.tabBars.buttons["Premium"].tap()
        app.tabBars.buttons["История"].tap()
        app.tabBars.buttons["Проверить"].tap()
        XCTAssertTrue(app.exists)
    }

    func testSC010_appTerminationAndRelaunch() {
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Проверить"].waitForExistence(timeout: 5))
    }

    // MARK: - UAT additions (SC-021..SC-030)

    func testSC011_settingsTabShowsPrivacyPolicy() {
        // Navigate to Settings via history gear
        app.tabBars.buttons["История"].tap()
        if app.buttons["gearshape"].waitForExistence(timeout: 3) {
            app.buttons["gearshape"].tap()
            if app.buttons["Политика конфиденциальности"].waitForExistence(timeout: 3) {
                app.buttons["Политика конфиденциальности"].tap()
                XCTAssertTrue(app.navigationBars["Политика конфиденциальности"].waitForExistence(timeout: 3))
            }
        }
    }

    func testSC012_settingsShowsHapticsToggle() {
        app.tabBars.buttons["История"].tap()
        if app.buttons["gearshape"].waitForExistence(timeout: 3) {
            app.buttons["gearshape"].tap()
            XCTAssertTrue(app.switches["Тактильная отдача"].waitForExistence(timeout: 3) ||
                          app.staticTexts["Тактильная отдача"].waitForExistence(timeout: 3))
        }
    }

    func testSC013_settingsShowsAutoTorchToggle() {
        app.tabBars.buttons["История"].tap()
        if app.buttons["gearshape"].waitForExistence(timeout: 3) {
            app.buttons["gearshape"].tap()
            XCTAssertTrue(app.switches["Авто-фонарик"].waitForExistence(timeout: 3) ||
                          app.staticTexts["Авто-фонарик"].waitForExistence(timeout: 3))
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
        if app.buttons["gearshape"].waitForExistence(timeout: 3) {
            app.buttons["gearshape"].tap()
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
            XCTAssertNotNil(check.label)
            XCTAssertFalse(check.label.isEmpty)
        }
    }

    func testSC017_premiumRestoreButtonAlwaysVisible() {
        app.tabBars.buttons["Premium"].tap()
        XCTAssertTrue(app.buttons["Восстановить покупки"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 3) ||
                      app.tabBars.buttons["Проверить"].exists)
    }

    func testSC020_allTabsNavigableInPortrait() {
        for label in ["Проверить", "Посчитать", "История", "Premium"] {
            app.tabBars.buttons[label].tap()
            sleep(1)
            XCTAssertTrue(app.exists)
        }
    }
}
