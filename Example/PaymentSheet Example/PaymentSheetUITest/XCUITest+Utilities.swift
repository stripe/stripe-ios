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

    func scrollToAndTap(in app: XCUIApplication) {
        while !self.exists {
            app.swipeUp()
        }
        self.tap()
    }

    func forceTapWhenHittableInTestCase(_ testCase: XCTestCase) {
        let predicate = NSPredicate(format: "hittable == true")
        testCase.expectation(for: predicate, evaluatedWith: self, handler: nil)
        testCase.waitForExpectations(timeout: 15.0, handler: nil)
        self.forceTapElement()
    }

    @discardableResult
    func waitForExistenceAndTap(timeout: TimeInterval = 4.0) -> Bool {
        if exists {
            forceTapElement()
            return true
        }

        guard waitForExistence(timeout: timeout) else {
            return false
        }
        forceTapElement()
        return true
    }

    func firstDescendant(withLabel label: String) -> XCUIElement {
        return descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
    }

    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else {
            return
        }

        // offset tap location a bit so cursor is at end of string
        let offsetTapLocation = coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6))
        offsetTapLocation.tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }

    /// Scrolls a picker wheel up by one option.
    func selectNextOption() {
        let startCoord = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoord = startCoord.withOffset(CGVector(dx: 0.0, dy: 30.0)) // 30pts = height of picker item
        endCoord.tap()
    }
}

extension Dictionary {
    subscript(string key: Key) -> String? {
        return self[key] as? String
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

    func waitForButtonOrStaticText(_ identifier: String, timeout: TimeInterval = 10.0) -> XCUIElement {
        if buttons[identifier].waitForExistence(timeout: timeout) {
            return buttons[identifier]
        }
        return staticTexts[identifier]
    }

    func tapCoordinate(at point: CGPoint) {
        let normalized = coordinate(withNormalizedOffset: .zero)
        let offset = CGVector(dx: point.x, dy: point.y)
        let coordinate = normalized.withOffset(offset)
        coordinate.tap()
    }
}

// https://gist.github.com/jlnquere/d2cd529874ca73624eeb7159e3633d0f
func scroll(collectionView: XCUIElement, toFindCellWithId identifier: String) -> XCUIElement? {
    return scroll(collectionView: collectionView) { collectionView in
        let cell = collectionView.cells[identifier]
        if cell.exists {
            return cell
        }
        return nil
    }
}

func scroll(collectionView: XCUIElement, toFindButtonWithId identifier: String) -> XCUIElement? {
    return scroll(collectionView: collectionView) { collectionView in
        let button = collectionView.buttons[identifier].firstMatch
        if button.exists {
            return button
        }
        return nil
    }
}

func scroll(collectionView: XCUIElement, toFindElementInCollectionView getElementInCollectionView: (XCUIElement) -> XCUIElement?) -> XCUIElement? {
    guard collectionView.elementType == .collectionView else {
        fatalError("XCUIElement is not a collectionView.")
    }

    var reachedTheEnd = false
    var allVisibleElements = [String]()

    while !reachedTheEnd {
        // Did we find our element ?
        if let element = getElementInCollectionView(collectionView) {
           return element
        }

        // If not: we store the list of all the elements we've got in the CollectionView
        let allElements = collectionView.cells.allElementsBoundByIndex.map({ $0.identifier })

        // Did we read then end of the CollectionView ?
        // i.e: do we have the same elements visible than before scrolling ?
        reachedTheEnd = (allElements == allVisibleElements)
        allVisibleElements = allElements

        // Then, we do a scroll right on the scrollview
        let startCoordinate = collectionView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.1, thenDragTo: collectionView.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.99)))
    }
    return nil
}
func scrollDown(scrollView: XCUIElement, toFindElement element: XCUIElement, maxTimesToScroll: Int = 1) -> XCUIElement? {
    guard scrollView.elementType == .scrollView else {
        fatalError("XCUIElement is not a scrollview.")
    }

    if element.isHittable {
        return element
    }

    var numTimesScrolled = 0
    while numTimesScrolled < maxTimesToScroll {

        let startCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.01, thenDragTo: scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        numTimesScrolled += 1

        if element.isHittable {
            return element
        }
    }
    return nil
}

extension XCTestCase {
    func fillCardData(_ app: XCUIApplication,
                      container: XCUIElement? = nil,
                      cardNumber: String? = nil,
                      postalEnabled: Bool = true,
                      tapCheckboxWithText checkboxText: String? = nil) throws {
        let context = container ?? app

        let numberField = context.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText(cardNumber ?? "4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText("123") // CVC
        if postalEnabled {
            app.typeText("12345") // Postal
        }
        if let checkboxText {
            let saveThisAccountToggle = app.switches[checkboxText]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()
            XCTAssertTrue(saveThisAccountToggle.isSelected)
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
        app.typeText("test-\(UUID().uuidString)@example.com")
    }
    func fillUSBankData_microdeposits(_ app: XCUIApplication,
                                      container: XCUIElement? = nil) throws {
        let context = container ?? app
        let routingField = context.textFields["manual_entry_routing_number_text_field"]
        routingField.forceTapWhenHittableInTestCase(self)
        app.typeText("110000000")

        // Dismiss keyboard, otherwise we can not see the next field
        // This is only an artifact in the (test) native version of the flow
        app.tapCoordinate(at: .init(x: 150, y: 150))

        let acctField = context.textFields["manual_entry_account_number_text_field"]
        acctField.forceTapWhenHittableInTestCase(self)
        app.typeText("000123456789")

        // Dismiss keyboard, otherwise we can not see the next field
        // This is only an artifact in the (test) native version of the flow
        app.tapCoordinate(at: .init(x: 150, y: 150))

        let acctConfirmField = context.textFields["manual_entry_account_number_confirmation_text_field"]
        acctConfirmField.forceTapWhenHittableInTestCase(self)
        app.typeText("000123456789")

        // Dismiss keyboard again otherwise we can not see the continue button
        // This is only an artifact in the (test) native version of the flow
        app.tapCoordinate(at: .init(x: 150, y: 150))
    }
    func fillSepaData(_ app: XCUIApplication,
                      iban: String = "DE89370400440532013000",
                      tapCheckboxWithText checkboxText: String? = nil,
                      container: XCUIElement? = nil) throws {
        let context = container ?? app
        let nameField = context.textFields["Full name"]
        nameField.forceTapWhenHittableInTestCase(self)
        app.typeText("John Doe")

        let emailField = context.textFields["Email"]
        emailField.forceTapWhenHittableInTestCase(self)
        app.typeText("test@example.com")

        let ibanField = context.textFields["IBAN"]
        ibanField.forceTapWhenHittableInTestCase(self)
        app.typeText(iban)

        let addressLine1 = context.textFields["Address line 1"]
        addressLine1.forceTapWhenHittableInTestCase(self)
        app.typeText("123 Main")
        context.buttons["Return"].tap()

        // Skip address 2
        context.buttons["Return"].tap()

        app.typeText("San Francisco")
        context.buttons["Return"].tap()

        context.pickerWheels.element.adjust(toPickerWheelValue: "California")
        context.buttons["Done"].tap()

        app.typeText("94016")
        context.buttons["Done"].tap()

        if let checkboxText {
            let saveThisAccountToggle = app.switches[checkboxText]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()
            XCTAssertTrue(saveThisAccountToggle.isSelected)
        }
    }

    func skipLinkSignup(_ app: XCUIApplication) {
        let notNowButton = app.buttons["Not now"]
        if notNowButton.waitForExistence(timeout: 10.0) {
            let keyboardCloseButton = app.toolbars.buttons["Done"]
            keyboardCloseButton.waitForExistenceAndTap() // Dismiss keyboard
            notNowButton.tap()
        }
    }

    func waitToDisappear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 0")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }

    func waitForNItemsExistence(_ target: Any?, count: Int) {
        let elementExistsPredicate = NSPredicate(format: "count == %d", count)
        expectation(for: elementExistsPredicate, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
