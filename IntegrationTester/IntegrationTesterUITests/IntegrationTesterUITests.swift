//
//  IntegrationTesterUITests.swift
//  IntegrationTesterUITests
//
//  Created by David Estes on 2/8/21.
//

// If these tests are failing, you may have the iOS Hardware Keyboard enabled.
// You can automate disabling this with:
// killall "Simulator"
// defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false

import XCTest
import Stripe

class IntegrationTesterUITests: XCTestCase {
    var app: XCUIApplication!
    var appLaunched = false
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        if (!appLaunched) {
            app.launch()
            appLaunched = true
        }
        popToMainMenu()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func popToMainMenu() {
        let menuButton = app.buttons["Examples"]
        if menuButton.exists {
            app.buttons["Examples"].tap()
        }
    }
  
  func fillCardData(_ app: XCUIApplication, number: String = "4242424242424242") throws {
    let numberField = app.textFields["card number"]
    XCTAssertTrue(numberField.waitForExistence(timeout: 10.0))
    numberField.tap()
    numberField.typeText(number)
    let expField = app.textFields["expiration date"]
    expField.typeText("1228")
    if STPCardValidator.brand(forNumber: number) == .amex {
        let cvcField = app.textFields["CVV"]
        cvcField.typeText("1234")
    } else {
        let cvcField = app.textFields["CVC"]
        cvcField.typeText("123")
    }
    let postalField = app.textFields["ZIP"]
    postalField.typeText("12345")
  }
    
    func testNoAuthentication(cardNumber: String, expectedResult: String = "Payment complete!") {
        self.popToMainMenu()
      let tablesQuery = app.tables
      let cardExampleElement = tablesQuery.cells["Card (PaymentIntents)"]
      cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

      let buyButton = app.buttons["Buy"]
      XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
      buyButton.forceTapElement()

      let statusView = app.staticTexts["Payment status view"]
      XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
      XCTAssertNotNil(statusView.label.range(of: expectedResult))
    }
    
    func test3DS2Authentication(cardNumber: String) {
        self.popToMainMenu()
        let tablesQuery = app.tables
        let cardExampleElement = tablesQuery.cells["Card (PaymentIntents)"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()

        let completeAuth = app.scrollViews.otherElements.staticTexts["Complete Authentication"]
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.tap()
        
        let successText = app.staticTexts["Payment complete!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
    
    func test3DS1Authentication(cardNumber: String) {
        self.popToMainMenu()
        let tablesQuery = app.tables
        let cardExampleElement = tablesQuery.cells["Card (PaymentIntents)"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)

        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.forceTapElement()
        
        let successText = app.staticTexts["Payment complete!"]
        XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
    }
  
  func testNoAuthenticationCustomCard() throws {
    let cardNumbers = [
        // Main test cards
        "4242424242424242", // visa
        "4000056655665556", // visa (debit)
        "5555555555554444", // mastercard
        "2223003122003222", // mastercard (2-series)
        "5200828282828210", // mastercard (debit)
        "5105105105105100", // mastercard (prepaid)
        "378282246310005",  // amex
        "371449635398431",  // amex
        "6011111111111117", // discover
        "6011000990139424", // discover
        "3056930009020004", // diners club
        "36227206271667",   // diners club (14 digit)
        "3566002020360505", // jcb
        "6200000000000005", // cup
        
        // Non-US
        "4000000760000002", // br
        "4000001240000000", // ca
        "4000004840008001", // mx
    ]
    for card in cardNumbers {
        testNoAuthentication(cardNumber: card)
    }
  }
  
  func testStandardCustomCard3DS1() throws {
    test3DS1Authentication(cardNumber: "4000000000003063")
  }
    
  func testStandardCustomCard3DS2() throws {
    test3DS2Authentication(cardNumber: "4000000000003220")
  }
    
  func testDeclinedCard() throws {
    testNoAuthentication(cardNumber: "4000000000000002", expectedResult: "declined")
  }
}


// There seems to be an issue with our SwiftUI buttons - XCTest fails to scroll to the button's position.
// Work around this by targeting a coordinate inside the button.
// https://stackoverflow.com/questions/33422681/xcode-ui-test-ui-testing-failure-failed-to-scroll-to-visible-by-ax-action
extension XCUIElement {
  func forceTapElement() {
    if self.isHittable {
      self.tap()
    } else {
      let coordinate: XCUICoordinate = self.coordinate(
        withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
      coordinate.tap()
    }
  }
}
