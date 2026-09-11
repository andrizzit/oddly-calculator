import XCTest

/// Runs against the real iOS application. No web mock or generated screenshot
/// is accepted as evidence for these workflows.
@MainActor
final class OddlyUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["calculator.display"].waitForExistence(timeout: 10))
    }

    override func tearDownWithError() throws {
        app.terminate()
        XCUIDevice.shared.orientation = .portrait
    }

    private func tap(_ identifiers: String..., file: StaticString = #filePath, line: UInt = #line) {
        for identifier in identifiers {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.exists || button.waitForExistence(timeout: 5), "Missing button \(identifier)", file: file, line: line)
            var scrollAttempts = 0
            while scrollAttempts < 5 && !button.isHittable {
                if button.frame.midY < app.frame.midY { app.swipeDown() }
                else { app.swipeUp() }
                scrollAttempts += 1
            }
            XCTAssertTrue(button.isHittable, "Button cannot be reached: \(identifier)", file: file, line: line)
            button.tap()
        }
    }

    private func expectResult(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let display = app.staticTexts["calculator.display"]
        XCTAssertEqual(display.label, "Result", file: file, line: line)
        XCTAssertEqual(display.value as? String, expected, file: file, line: line)
    }

    private func discoverCosmicReceipt() {
        tap("key.6", "key.multiply", "key.7", "key.equals")
        expectResult("42")
    }

    private func relaunchPreservingStorage() {
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["calculator.display"].waitForExistence(timeout: 10))
    }

    private func attachScreenshot(_ name: String, wholeScreen: Bool = false) {
        let screenshot = XCTAttachment(screenshot: wholeScreen ? XCUIScreen.main.screenshot() : app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func openCollection() {
        let button = app.buttons["toolbar.collection"]
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        XCTAssertGreaterThanOrEqual(button.frame.width, 44)
        tap("toolbar.collection")
        let done = app.buttons["collection.done"]
        XCTAssertTrue(done.exists || done.waitForExistence(timeout: 5),
                      "The entire Curiosity cabinet button must open its sheet")
    }

    func testImmediateExecutionBreadcrumbRepeatedEqualsAndFreshInput() {
        tap("key.2", "key.add", "key.3", "key.multiply")
        expectResult("5")
        XCTAssertEqual(app.staticTexts["calculator.expression"].value as? String, "5 ×")
        tap("key.4", "key.equals")
        expectResult("20")
        XCTAssertEqual(app.staticTexts["calculator.expression"].value as? String, "5 × 4 =")
        attachScreenshot("Real iOS result and immediate execution breadcrumb")
        tap("key.equals")
        expectResult("80")
        tap("key.7", "key.equals")
        expectResult("7")
    }

    func testExactDecimalAndContextualPercent() {
        tap("key.0", "key.decimal", "key.1", "key.add", "key.0", "key.decimal", "key.2", "key.equals")
        expectResult("0.3")
        tap("key.clear", "key.2", "key.0", "key.0", "key.add", "key.1", "key.0", "key.percent", "key.equals")
        expectResult("220")
    }

    func testDeleteAndDivisionErrorRecovery() {
        let delete = app.buttons["key.delete"]
        XCTAssertGreaterThanOrEqual(delete.frame.height, 44)
        XCTAssertGreaterThanOrEqual(delete.frame.width, 44)
        tap("key.1", "key.2", "key.3", "key.delete")
        expectResult("12")
        tap("key.divide", "key.0", "key.equals")
        expectResult("Error")
        tap("key.9", "key.add", "key.1", "key.equals")
        expectResult("10")
        tap("toolbar.history")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.recall.")).count, 1)
        let copy = app.buttons["Copy 10"]
        XCTAssertTrue(copy.exists)
        XCTAssertGreaterThanOrEqual(copy.frame.height, 44)
        XCTAssertGreaterThanOrEqual(copy.frame.width, 44)
    }

    func testScienceDrawerWorksInPortrait() {
        tap("key.8", "key.1", "mode.science", "key.squareRoot")
        expectResult("9")
        tap("key.square")
        expectResult("81")
    }

    func testHistorySurvivesRelaunchAndRecallsExactValue() {
        tap("key.1", "key.divide", "key.8", "key.equals")
        expectResult("0.125")
        relaunchPreservingStorage()
        tap("toolbar.history")
        let record = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.recall.")).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        record.tap()
        expectResult("0.125")
        tap("key.multiply", "key.8", "key.equals")
        expectResult("1")
    }

    func testDiscoveryPersistsAndNeverBlocksInput() {
        let equals = app.buttons["key.equals"]
        var scrollAttempts = 0
        while scrollAttempts < 5 && !equals.isHittable {
            app.swipeUp()
            scrollAttempts += 1
        }
        let positionBeforeDiscovery = equals.frame
        discoverCosmicReceipt()
        XCTAssertEqual(equals.frame.minY, positionBeforeDiscovery.minY, accuracy: 1,
                       "A discovery must not move the calculator keys")
        attachScreenshot("Real iOS first discovery")
        tap("key.2", "key.add", "key.2", "key.equals")
        expectResult("4")
        relaunchPreservingStorage()
        openCollection()
        XCTAssertTrue(app.descendants(matching: .any)["collection.discovered.cosmic-receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["collection.locked.cosmic-receipt"].exists)
        attachScreenshot("Real iOS curiosity cabinet")
    }

    func testCalmPausesDiscoveriesAndSettingPersists() {
        tap("toolbar.settings")
        let personality = app.segmentedControls["settings.personality"]
        XCTAssertTrue(personality.waitForExistence(timeout: 5))
        personality.buttons["Calm"].tap()
        attachScreenshot("Real iOS settings")
        tap("settings.done")
        discoverCosmicReceipt()
        openCollection()
        XCTAssertTrue(app.descendants(matching: .any)["collection.locked.cosmic-receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["collection.discovered.cosmic-receipt"].exists)
        tap("collection.done")
        relaunchPreservingStorage()
        tap("toolbar.settings")
        XCTAssertTrue(app.segmentedControls["settings.personality"].buttons["Calm"].isSelected)
    }

    func testClearingHistoryPreservesDiscoveriesAfterRelaunch() {
        discoverCosmicReceipt()
        tap("toolbar.history", "history.clear")
        let confirm = app.buttons["Clear history"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.recall.")).count, 0)
        tap("history.done")
        relaunchPreservingStorage()
        tap("toolbar.history")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.recall.")).count, 0)
        tap("history.done")
        openCollection()
        XCTAssertTrue(app.descendants(matching: .any)["collection.discovered.cosmic-receipt"].waitForExistence(timeout: 5))
    }

    func testLargeTextLandscapeKeysRemainReachable() {
        app.terminate()
        app.launchArguments = ["--uitesting-reset", "--uitesting-large-type"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate { [weak self] _, _ in
                guard let frame = self?.app.frame else { return false }
                return frame.width > frame.height
            },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed,
                       "Wait for the real application to finish rotating")
        let equals = app.buttons["key.equals"]
        var scrollAttempts = 0
        while scrollAttempts < 5 && (!equals.isHittable || !app.frame.contains(equals.frame)) {
            app.swipeUp()
            scrollAttempts += 1
        }
        XCTAssertTrue(equals.isHittable)
        XCTAssertGreaterThanOrEqual(equals.frame.height, 44)
        XCTAssertGreaterThanOrEqual(equals.frame.width, 44)
        XCTAssertTrue(app.frame.contains(equals.frame),
                      "Equals must fit completely: key \(equals.frame), app \(app.frame)")
        equals.tap()
        attachScreenshot("Real iOS large text landscape", wholeScreen: true)
    }
}
