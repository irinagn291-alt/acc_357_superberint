import XCTest

@MainActor
final class StudioJourney: XCTestCase {
    func testCreateStoreReopenAndPrepareLabelForPrinting() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-registration_attempted", "YES", "-cached_content_url", ""]
        let flock = "Orchard " + String(UUID().uuidString.prefix(8))
        let note = "Collected before sunrise"
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Labels"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Labels"].tap()

        XCTAssertTrue(app.staticTexts["Label studio"].waitForExistence(timeout: 12))
        attachScreen(app, named: "01 Studio")
        app.buttons["collection"].tap()
        let archive = app.buttons["savedLabel"].firstMatch
        if archive.exists { attachScreen(app, named: "Saved library on launch") }
        let newLabel = app.buttons["newLabel"]
        reveal(newLabel, in: app)
        newLabel.tap()
        let keepCurrent = app.buttons["Save and continue"]
        if keepCurrent.exists { keepCurrent.tap() }

        let market = app.buttons["style-market"]
        reveal(market, in: app)
        market.tap()
        XCTAssertTrue(market.isSelected)
        let edit = app.buttons["editLabel"]
        reveal(edit, in: app)
        edit.tap()

        let stepper = app.steppers["eggStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()

        app.buttons["clearFlock"].tap()
        app.textFields["flockName"].tap()
        app.textFields["flockName"].typeText(flock)
        let doneTyping = app.buttons["Done"].firstMatch
        if doneTyping.exists && doneTyping.isHittable { doneTyping.tap() }
        let noteField = app.descendants(matching: .any).matching(identifier: "labelNote").firstMatch
        reveal(noteField, in: app)
        app.buttons["clearNote"].tap()
        noteField.tap()
        noteField.typeText(note)
        if doneTyping.exists && doneTyping.isHittable { doneTyping.tap() }
        app.buttons["applyEdit"].tap()

        let proof = app.descendants(matching: .any).matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label CONTAINS %@ AND label CONTAINS %@ AND label CONTAINS %@",
            "Label proof. Market", flock, "11 eggs", note
        )).firstMatch
        XCTAssertTrue(proof.waitForExistence(timeout: 5))
        let save = app.buttons["saveLabel"]
        save.tap()
        XCTAssertFalse(save.isEnabled)

        app.buttons["collection"].tap()
        reveal(newLabel, in: app)
        newLabel.tap()
        XCTAssertFalse(proof.exists)

        app.buttons["collection"].tap()
        let savedRow = app.buttons.matching(NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@", "savedLabel", flock
        )).firstMatch
        XCTAssertTrue(savedRow.waitForExistence(timeout: 5))
        savedRow.tap()
        XCTAssertTrue(proof.waitForExistence(timeout: 5))
        XCTAssertTrue(market.isSelected)

        app.buttons["printLabel"].tap()
        let letter = app.buttons["paper-letter"]
        XCTAssertTrue(letter.waitForExistence(timeout: 5))
        letter.tap()
        let share = app.buttons["sharePDF"]
        XCTAssertTrue(share.waitForExistence(timeout: 10))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: share)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        attachScreen(app, named: "02 Print sheet")
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func attachScreen(_ app: XCUIApplication, named name: String) {
        let frame = XCTAttachment(screenshot: app.screenshot())
        frame.name = name
        frame.lifetime = .keepAlways
        add(frame)
    }
}
