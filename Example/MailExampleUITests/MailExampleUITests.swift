//
//  MailExampleUITests.swift
//  MailExampleUITests
//
//  Created by Ilia Sedov on 18.05.2022.
//

import XCTest

class MailExampleUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testActionTappableFromUITest() throws {
        let app = XCUIApplication()
        app.launch()

        app.tables.cells.staticTexts["Custom Content Action Collection"].tap()

        let toDeleteCellText = "Hello, The gerbils at the Pragmatic Bookstore have just finished hand-crafting your eBook of Swift Style. It's available for download at the following URL:"
        let cell = findCell(label: toDeleteCellText, in: app)
        cell.swipeLeft(velocity: XCUIGestureVelocity.default)

        app.buttons["Trash"].tap()

        let removed = NSPredicate(format: "exists == 0")
        expectation(for: removed, evaluatedWith: cell, handler: nil)
        waitForExpectations(timeout: 1.5, handler: nil)
    }

    func testActionCustomAccessibilityLabel() {
        let app = XCUIApplication()
        app.launch()

        app.tables.cells.staticTexts["Custom Content Action Collection"].tap()

        let toDeleteCellText = "Hello, The gerbils at the Pragmatic Bookstore have just finished hand-crafting your eBook of Swift Style. It's available for download at the following URL:"
        let cell = findCell(label: toDeleteCellText, in: app)
        cell.swipeLeft(velocity: XCUIGestureVelocity.default)

        let flagButton = app.buttons["Accessible Button"]
        flagButton.tap()

        let actionsClosed = NSPredicate(format: "exists == 0")
        expectation(for: actionsClosed, evaluatedWith: flagButton, handler: nil)
        waitForExpectations(timeout: 1.5, handler: nil)

    }


    private func findCell(label: String, in app: XCUIApplication) -> XCUIElement {
        app.collectionViews
            .cells
            .staticTexts
            .containing(.init(format: "label CONTAINS %@", label))
            .firstMatch
    }
}
