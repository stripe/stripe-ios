//
//  IntegrationTesterUITests.swift
//  IntegrationTesterUITests
//
//  Created by David Estes on 2/8/21.
//

import XCTest

class IntegrationTesterUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
  
  func fillCardData(_ app: XCUIApplication, number: String = "4242424242424242") throws {
    let numberField = app.textFields["card number"]
    XCTAssertTrue(numberField.waitForExistence(timeout: 10.0))
    numberField.tap()
    numberField.typeText(number)
    let expField = app.textFields["expiration date"]
    expField.typeText("1228")
    let cvcField = app.textFields["CVC"]
    cvcField.typeText("123")
    let postalField = app.textFields["ZIP"]
    postalField.typeText("12345")
  }
  
  // If these tests are failing, you may have the iOS Hardware Keyboard enabled.
  // You can automate disabling this with:
  // killall "Simulator"
  // defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
  func testStandardCustomCard() throws {
    let app = XCUIApplication()
    app.launch()
    
    let tablesQuery = app.tables
    let cardExampleElement = tablesQuery.cells["Card Example"]
    cardExampleElement.tap()
    try! fillCardData(app)


    let buyButton = app.buttons["Buy"]
    XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
    buyButton.forceTapElement()

    let successText = app.staticTexts["Payment complete!"]
    XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
  }
  
  func testStandardCustomCard3DS2() throws {
    let app = XCUIApplication()
    app.launch()
    
    let tablesQuery = app.tables
    let cardExampleElement = tablesQuery.cells["Card Example"]
    cardExampleElement.tap()
    try! fillCardData(app, number: "4000000000003220")

    let buyButton = app.buttons["Buy"]
    XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
    buyButton.forceTapElement()

    let completeAuth = app.scrollViews.otherElements.staticTexts["Complete Authentication"]
    XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
    completeAuth.tap()
    
    let successText = app.staticTexts["Payment complete!"]
    XCTAssertTrue(successText.waitForExistence(timeout: 10.0))
  }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
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
