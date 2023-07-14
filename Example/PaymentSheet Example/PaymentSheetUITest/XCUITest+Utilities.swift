//
//  XCUITest+Utilities.swift
//  PaymentSheetUITest
//
//  Created by Yuki Tokuhiro on 8/20/21.
//  Copyright © 2021 stripe-ios. All rights reserved.
//

import XCTest

// There seems to be an issue with our SwiftUI buttons - XCTest fails to scroll to the button's position.
// Work around this by targeting a coordinate inside the button.
// https://stackoverflow.com/questions/33422681/xcode-ui-test-ui-testing-failure-failed-to-scroll-to-visible-by-ax-action
extension XCUIElement {
    func forceTapElement() {
        if self.isHittable {
            self.tap()
        } else {
            // Tap the middle of the element.
            // (Sometimes the edges of rounded buttons aren't tappable in certain web elements.)
            let coordinate: XCUICoordinate = self.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }

    func forceTapWhenHittableInTestCase(_ testCase: XCTestCase) {
        let predicate = NSPredicate(format: "hittable == true")
        testCase.expectation(for: predicate, evaluatedWith: self, handler: nil)
        testCase.waitForExpectations(timeout: 15.0, handler: nil)
        self.forceTapElement()
    }

    @discardableResult
    func waitForExistenceAndTap(timeout: TimeInterval = 4.0) -> Bool {
        guard waitForExistence(timeout: timeout) else {
            return false
        }
        forceTapElement()
        return true
    }
}

// MARK: - XCUIApplication

extension XCUIApplication {
    /// Types a text using the software keyboard.
    ///
    /// This method is significantly slower than `XCUIElement.typeText()` but it works with custom controls.
    ///
    /// - Parameter text: Text to type.
    func typeTextWithKeyboard(_ text: String) {
        for key in text {
            self.keys[String(key)].tap()
        }
    }
}

// https://gist.github.com/jlnquere/d2cd529874ca73624eeb7159e3633d0f
func scroll(collectionView: XCUIElement, toFindCellWithId identifier: String) -> XCUIElement? {
    guard collectionView.elementType == .collectionView else {
        fatalError("XCUIElement is not a collectionView.")
    }

    var reachedTheEnd = false
    var allVisibleElements = [String]()

    while !reachedTheEnd {
        let cell = collectionView.cells[identifier]

        // Did we find our cell ?
        if cell.exists {
            return cell
        }

        // If not: we store the list of all the elements we've got in the CollectionView
        let allElements = collectionView.cells.allElementsBoundByIndex.map({ $0.identifier })

        // Did we read then end of the CollectionView ?
        // i.e: do we have the same elements visible than before scrolling ?
        reachedTheEnd = (allElements == allVisibleElements)
        allVisibleElements = allElements

        // Then, we do a scroll right on the scrollview
        let startCoordinate = collectionView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.01, thenDragTo: collectionView.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.99)))
    }
    return nil
}

extension XCTestCase {
    func fillCardData(_ app: XCUIApplication,
                      container: XCUIElement? = nil,
                      cardNumber: String? = nil,
                      postalEnabled: Bool = true) throws {
        let context = container ?? app

        let numberField = context.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText(cardNumber ?? "4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        if postalEnabled {
            app.toolbars.buttons["Done"].tap() // Country picker toolbar's "Done" button
            app.typeText("12345") // Postal
        }
    }

    func fillUSBankData(_ app: XCUIApplication,
                        container: XCUIElement? = nil) throws {
        let context = container ?? app
        let nameField = context.textFields["Full name"]
        nameField.forceTapWhenHittableInTestCase(self)
        app.typeText("John Doe")

        let emailField = context.textFields["Email"]
        emailField.forceTapWhenHittableInTestCase(self)
        app.typeText("test@example.com")
    }

    func waitToDisappear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 0")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }

    func reload(_ app: XCUIApplication, settings: PaymentSheetTestPlaygroundSettings) {
        app.buttons["Reload"].tap()
        waitForReload(app, settings: settings)
    }

    func waitForReload(_ app: XCUIApplication, settings: PaymentSheetTestPlaygroundSettings) {
        if settings.uiStyle == .paymentSheet {
            let presentButton = app.buttons["Present PaymentSheet"]
            expectation(
                for: NSPredicate(format: "enabled == true"),
                evaluatedWith: presentButton,
                handler: nil
            )
            waitForExpectations(timeout: 10, handler: nil)
        } else {
            let confirm = app.buttons["Confirm"]
            expectation(
                for: NSPredicate(format: "enabled == true"),
                evaluatedWith: confirm,
                handler: nil
            )
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
    func loadPlayground(_ app: XCUIApplication, _ settings: PaymentSheetTestPlaygroundSettings) {
        if #available(iOS 15.0, *) {
            // Doesn't work on 16.4. Seems like a bug, can't see any confirmation that this works online.
            //   var urlComponents = URLComponents(string: "stripe-paymentsheet-example://playground")!
            //   urlComponents.query = settings.base64Data
            //   app.open(urlComponents.url!)
            // This should work, but we get an "Open in 'PaymentSheet Example'" consent dialog the first time we run it.
            // And while the dialog is appearing, `open()` doesn't return, so we can't install an interruption handler or anything to handle it.
            //   XCUIDevice.shared.system.open(urlComponents.url!)
            app.launchEnvironment = app.launchEnvironment.merging(["STP_PLAYGROUND_DATA": settings.base64Data]) { (_, new) in new }
            app.launch()
        } else {
            XCTFail("This test is only supported on iOS 15.0 or later.")
        }
        waitForReload(app, settings: settings)
    }
    func waitForReload(_ app: XCUIApplication, settings: CustomerSheetTestPlaygroundSettings) {
        let customerId = app.textFields["CustomerId"]
        expectation(
            for: NSPredicate(format: "self BEGINSWITH 'cus_'"),
            evaluatedWith: customerId.value,
            handler: nil
        )
        waitForExpectations(timeout: 10, handler: nil)
    }
    func loadPlayground(_ app: XCUIApplication, _ settings: CustomerSheetTestPlaygroundSettings) {
        if #available(iOS 15.0, *) {
            app.launchEnvironment = app.launchEnvironment.merging(["STP_CUSTOMERSHEET_PLAYGROUND_DATA": settings.base64Data]) { (_, new) in new }
            app.launch()
        } else {
            XCTFail("This test is only supported on iOS 15.0 or later.")
        }
        waitForReload(app, settings: settings)
    }
}
