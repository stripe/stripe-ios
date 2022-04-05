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
}

// https://gist.github.com/jlnquere/d2cd529874ca73624eeb7159e3633d0f
func scroll(collectionView: XCUIElement, toFindCellWithId identifier:String) -> XCUIElement? {
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
        let allElements = collectionView.cells.allElementsBoundByIndex.map({$0.identifier})
        
        // Did we read then end of the CollectionView ?
        // i.e: do we have the same elements visible than before scrolling ?
        reachedTheEnd = (allElements == allVisibleElements)
        allVisibleElements = allElements
        
        // Then, we do a scroll right on the scrollview
        let startCoordinate = collectionView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.99))
        startCoordinate.press(forDuration: 0.01, thenDragTo: collectionView.coordinate(withNormalizedOffset:CGVector(dx: 0.1, dy: 0.99)))
    }
    return nil
}


extension XCTestCase {
    func fillCardData(_ app: XCUIApplication) throws {
        let numberField = app.textFields["Card number"]
        numberField.forceTapWhenHittableInTestCase(self)
        numberField.typeText("4242424242424242")
        let expField = app.textFields["expiration date"]
        expField.forceTapWhenHittableInTestCase(self)
        expField.typeText("1228")
        let cvcField = app.textFields["CVC"]
        cvcField.forceTapWhenHittableInTestCase(self)
        cvcField.typeText("123")
        let postalField = app.textFields["ZIP"]
        postalField.forceTapWhenHittableInTestCase(self)
        postalField.typeText("12345")
    }

    func waitToDisappear(_ target: Any?) {
        let exists = NSPredicate(format: "exists == 0")
        expectation(for: exists, evaluatedWith: target, handler: nil)
        waitForExpectations(timeout: 60.0, handler: nil)
    }
    
    func reload(_ app: XCUIApplication) {
        app.buttons["Reload PaymentSheet"].tap()

        let checkout = app.buttons["Checkout (Complete)"]
        expectation(
            for: NSPredicate(format: "enabled == true"),
            evaluatedWith: checkout,
            handler: nil
        )
        waitForExpectations(timeout: 10, handler: nil)
    }

    func loadPlayground(_ app: XCUIApplication, settings: [String: String]) {
        app.staticTexts["PaymentSheet (test playground)"].tap()

        // Wait for the screen to load
        XCTAssert(app.navigationBars["Test Playground"].waitForExistence(timeout: 10))

        for (setting, value) in settings {
            app.segmentedControls["\(setting)_selector"].buttons[value].tap()
        }

        reload(app)
    }
}
