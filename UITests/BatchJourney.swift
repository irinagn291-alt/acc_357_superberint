import XCTest

@MainActor
final class BatchJourney: XCTestCase {
    func testSplitSaveReprintAndShare() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-registration_attempted", "YES", "-cached_content_url", ""]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Labels"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Labels"].tap()
        // Use a fresh template even if an earlier run left a different carton size in the studio.
        app.buttons["collection"].tap()
        let newLabel = app.buttons["newLabel"]
        tapInScroll(newLabel, towardBottom: true, app: app)
        let replace = app.buttons["Continue without saving"]
        if replace.exists { replace.tap() }

        app.buttons["openBatches"].tap()
        let total = app.textFields["batchTotal"]
        XCTAssertTrue(total.waitForExistence(timeout: 12))
        total.tap()
        total.typeText("23")
        app.buttons["Done"].tap()
        let layout = app.descendants(matching: .any).matching(identifier: "batchPacking").firstMatch
        XCTAssertTrue(layout.waitForExistence(timeout: 12))
        XCTAssertTrue(layout.label.contains("2 × 10 + 1 × 3"), layout.label)
        let save = app.buttons["batchSave"]
        tapInScroll(save, towardBottom: true, app: app)
        XCTAssertFalse(save.isEnabled)
        let saved = XCTAttachment(screenshot: app.screenshot())
        saved.name = "Pack 23 eggs"
        saved.lifetime = .keepAlways
        add(saved)

        tapInScroll(app.buttons["batchHistoryTab"], towardBottom: false, app: app)
        let record = app.descendants(matching: .any).matching(identifier: "batchRecord").firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 12), app.debugDescription)
        record.tap()
        tapInScroll(app.buttons["batchReprint"], towardBottom: true, app: app)
        XCTAssertFalse(app.steppers["copiesStepper"].exists)
        let first = app.buttons["firstSlotPicker"]
        XCTAssertTrue(first.waitForExistence(timeout: 12))
        first.tap()
        app.buttons["6 · bottom right"].tap()
        let next = app.buttons["nextPDFPage"]
        tapInScroll(next, towardBottom: true, app: app)
        let page = app.staticTexts["pdfPageNumber"]
        XCTAssertEqual(page.label, "Sheet 2 of 2")
        let sheet = XCTAttachment(screenshot: app.screenshot())
        sheet.name = "Second sheet with remainder"
        sheet.lifetime = .keepAlways
        add(sheet)

        app.buttons["sharePDF"].tap()
        let activity = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ OR identifier == %@ OR label IN %@ OR (label BEGINSWITH[c] %@ AND label CONTAINS[c] %@)",
            "ActivityListView", "UIActivityContentView", ["Save to Files", "Save to Files", "Save to Files", "Copy", "Copy"], "Roostprint-", "A4"
        )).firstMatch
        XCTAssertTrue(activity.waitForExistence(timeout: 12), "The system share sheet should offer the generated PDF.")
    }

    func testGuideOpensOfflinePolicy() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-registration_attempted", "YES", "-cached_content_url", ""]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Labels"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Labels"].tap()
        app.buttons["guide"].tap()
        let privacy = app.buttons["openPrivacy"]
        tapInScroll(privacy, towardBottom: true, app: app)
        XCTAssertTrue(app.staticTexts["Your records"].waitForExistence(timeout: 12))
    }

    private func tapInScroll(_ element: XCUIElement, towardBottom: Bool, app: XCUIApplication) {
        for _ in 0..<5 {
            if element.exists && element.isHittable { element.tap(); return }
            if towardBottom { app.swipeUp() } else { app.swipeDown() }
        }
        XCTFail("Control not reachable: " + element.description)
    }
}
