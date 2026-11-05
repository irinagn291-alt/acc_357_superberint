import XCTest

@MainActor
final class FarmJourney: XCTestCase {
    func testCollectionSaleStockAndInsightsInEnglish() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-registration_attempted", "YES", "-cached_content_url", "", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Overview"].waitForExistence(timeout: 15))
        for title in ["Stock", "Sales", "Insights", "Labels"] { XCTAssertTrue(app.tabBars.buttons[title].exists) }
        app.buttons["farm.addCollection"].tap()
        let total = app.textFields["batchTotal"]
        XCTAssertTrue(total.waitForExistence(timeout: 10))
        total.tap(); total.typeText("23")
        app.buttons["Done"].firstMatch.tap()
        reveal(app.buttons["batchSave"], in: app)
        app.buttons["batchSave"].tap()
        XCTAssertFalse(app.buttons["batchSave"].isEnabled)
        app.buttons["Close"].firstMatch.tap()
        app.buttons["farm.addSale"].tap()
        XCTAssertTrue(app.textFields["movement.quantity"].waitForExistence(timeout: 10))
        app.textFields["movement.quantity"].tap(); app.textFields["movement.quantity"].typeText("6")
        app.buttons["Done"].firstMatch.tap()
        app.textFields["movement.amount"].tap(); app.textFields["movement.amount"].typeText("4.50")
        app.buttons["Done"].firstMatch.tap()
        app.textFields["movement.customer"].tap(); app.textFields["movement.customer"].typeText("Alex QA")
        app.buttons["Done"].firstMatch.tap()
        app.buttons["movement.save"].tap()
        app.tabBars.buttons["Stock"].tap()
        screenshot(app, "Stock after sale")
        app.tabBars.buttons["Sales"].tap()
        XCTAssertTrue(app.staticTexts["Alex QA"].waitForExistence(timeout: 10))
        screenshot(app, "Sales ledger")
        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.staticTexts["Collection trend"].waitForExistence(timeout: 10))
        screenshot(app, "Insights")
        app.tabBars.buttons["Overview"].tap()
        screenshot(app, "Farm overview")
        app.terminate(); app.launch()
        app.tabBars.buttons["Sales"].tap()
        XCTAssertTrue(app.staticTexts["Alex QA"].waitForExistence(timeout: 10))
    }
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 { if element.exists && element.isHittable { return }; app.swipeUp() }
        XCTFail("Control not reachable: \(element)")
    }
    private func screenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
