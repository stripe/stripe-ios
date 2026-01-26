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

    /// Dismisses the keyboard by tapping the Done button on the toolbar, or tapping outside the keyboard.
    func fc_dismissKeyboard() {
        // Try the toolbar Done button first (iOS 18 and earlier)
        let doneButtonByLabel = toolbars.buttons["Done"]
        if doneButtonByLabel.waitForExistence(timeout: 1) {
            doneButtonByLabel.tap()
            return
        }
        // iOS 26 fallback: tap on the title label to dismiss the keyboard
        // This works for FinancialConnections flows
        let fcTitleLabel = otherElements["fc_pane_title_label"]
        if fcTitleLabel.exists {
            fcTitleLabel.tap()
            return
        }
        // Last resort: tap near the top of the screen
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
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

// MARK: - Address Autocomplete Extension
extension XCUIApplication {
    /// Fills an address field using autocomplete flow only
    /// - Parameters:
    ///   - addressFieldIdentifier: The identifier for the address field (e.g., "Address", "Address line 1")
    ///   - searchTerm: The search term to type for autocomplete (e.g., "354 Oyster Point")
    ///   - expectedResult: The expected autocomplete result to look for (e.g., "354 Oyster Point Blvd")
    ///   - context: The context element to search within (defaults to self)
    ///   - needsDoneButton: Whether to tap Done button after autocomplete selection
    func fillAddressWithAutocomplete(
        addressFieldIdentifier: String = "Address",
        searchTerm: String = "354 Oyster Point",
        expectedResult: String = "354 Oyster Point Blvd",
        context: XCUIElement? = nil
    ) {
        let contextElement = context ?? self
        let addressField = contextElement.textFields[addressFieldIdentifier]

        // Tap the address field
        addressField.tap()

        // Wait for autocomplete view to appear
        XCTAssertTrue(staticTexts["Enter address manually"].waitForExistence(timeout: 2), "Autocomplete view should appear")

        handleiOSKeyboardTipIfNeeded()

        // Proceed with autocomplete flow
        let autocompleteTextField = textFields["Address"].firstMatch
        autocompleteTextField.waitForExistenceAndTap()
        typeText(searchTerm)

        // Wait for and tap the matching autocomplete result
        let searchedCell = tables.element(boundBy: 0).cells.containing(NSPredicate(format: "label CONTAINS %@", expectedResult)).element
        XCTAssertTrue(searchedCell.waitForExistence(timeout: 5), "Autocomplete result '\(expectedResult)' should appear")
        searchedCell.tap()
    }

    // In CI, we often have fresh emulators that encounter this "Tip" that prevents our tests from moving forward:
    // "Speed up your typing by sliding your finger across the letters to compose a word" / Continue
    func handleiOSKeyboardTipIfNeeded() {
        let optionalTipLabel = staticTexts["Speed up your typing by sliding your finger across the letters to compose a word."]
        if optionalTipLabel.waitForExistence(timeout: 2.0) {
            let continueButton = buttons["Continue"].firstMatch
            if continueButton.waitForExistence(timeout: 2.0) {
                continueButton.forceTapElement()
            }
        }
    }
}

extension XCTestCase {
    func fillCardData(_ app: XCUIApplication,
                      container: XCUIElement? = nil,
                      cardNumber: String? = nil,
                      cvc: String = "123",
                      postalEnabled: Bool = true,
                      tapCheckboxWithText checkboxText: String? = nil,
                      disableDefaultOptInIfNeeded: Bool = false) throws {
        let context = container ?? app

        let numberField = context.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        app.typeText(cardNumber ?? "4242424242424242")
        app.typeText("1228") // Expiry
        app.typeText(cvc) // CVC
        if postalEnabled {
            app.typeText("12345") // Postal
        }
        if let checkboxText {
            let saveThisAccountToggle = app.switches[checkboxText]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()
            XCTAssertTrue(saveThisAccountToggle.isSelected)
        }
        if disableDefaultOptInIfNeeded {
            let saveSwitch = app.switches.containing(NSPredicate(format: "label CONTAINS[c] 'Save'")).firstMatch
            if saveSwitch.exists && saveSwitch.isSelected {
                saveSwitch.tap()
            }
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
        context.buttons["test_mode_autofill_button"].tap()
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

        app.fillAddressWithAutocomplete(context: context)

        if let checkboxText {
            let saveThisAccountToggle = app.switches[checkboxText]
            XCTAssertFalse(saveThisAccountToggle.isSelected)
            saveThisAccountToggle.tap()
            XCTAssertTrue(saveThisAccountToggle.isSelected)
        }
    }

    func skipLinkSignup(_ app: XCUIApplication) {
        // This handles the FinancialConnections networking Link signup screen
        let notNowButton = app.buttons["networking_link_signup_footer_view.not_now_button"]
        if notNowButton.waitForExistence(timeout: 10.0) {
            app.fc_dismissKeyboard()
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
