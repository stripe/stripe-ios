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

enum ConfirmationBehavior {
    // No confirmation needed
    case none
    // authorize a 3DS1 transaction
    case threeDS1
    // authorize a 3DS2 transaction
    case threeDS2
}

class IntegrationTesterUITests: XCTestCase {
    var app: XCUIApplication!
    var appLaunched = false
    
    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchEnvironment = ["UITesting": "true"]
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
        let menuButton = app.buttons["Integrations"]
        if menuButton.exists {
            menuButton.tap()
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
    
    func testAuthentication(cardNumber: String, expectedResult: String = "Payment complete!", confirmationBehavior: ConfirmationBehavior = .none) {
        print("Testing \(cardNumber)")
        self.popToMainMenu()
        let tablesQuery = app.tables
        
        let cardExampleElement = tablesQuery.cells["Card"]
        cardExampleElement.tap()
        try! fillCardData(app, number: cardNumber)
        
        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        switch confirmationBehavior {
        case .none: break
        case .threeDS1:
            let webViewsQuery = app.webViews
            let completeAuth = webViewsQuery.buttons["COMPLETE AUTHENTICATION"]
            XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
            completeAuth.forceTapElement()
        case .threeDS2:
            let completeAuth = app.scrollViews.otherElements.staticTexts["Complete Authentication"]
            XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
            completeAuth.tap()
        }
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: expectedResult))
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
            testAuthentication(cardNumber: card)
        }
    }
    
    func testStandardCustomCard3DS1() throws {
        testAuthentication(cardNumber: "4000000000003063", confirmationBehavior: .threeDS1)
    }
    
    func testStandardCustomCard3DS2() throws {
        testAuthentication(cardNumber: "4000000000003220", confirmationBehavior: .threeDS2)
    }
    
    func testDeclinedCard() throws {
        testAuthentication(cardNumber: "4000000000000002", expectedResult: "declined")
    }
    
    func testSetupIntents() throws {
        self.popToMainMenu()
        let tablesQuery = app.tables
        
        let cardExampleElement = tablesQuery.cells["Card (SetupIntents)"]
        cardExampleElement.tap()
        try! fillCardData(app, number: "4242424242424242")
        
        let buyButton = app.buttons["Setup"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "complete!"))
    }
    
    func testApplePay() throws {
        self.popToMainMenu()
        let tablesQuery = app.tables
        
        let applePayElement = tablesQuery.cells["Apple Pay"]
        applePayElement.tap()
        let applePayButton = app.buttons["Buy with Apple Pay"]
        XCTAssertTrue(applePayButton.waitForExistence(timeout: 10.0))
        applePayButton.tap()
        
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        _ = applePay.wait(for: .runningForeground, timeout: 10)
        
        var cardButton = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"]
        XCTAssertTrue(cardButton.waitForExistence(timeout: 10.0))
        cardButton.forceTapElement()
        
        cardButton = applePay.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].firstMatch
        XCTAssertTrue(cardButton.waitForExistence(timeout: 10.0))
        cardButton.forceTapElement()
        
        let payButton = applePay.buttons["Pay with Passcode"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 10.0))
        payButton.forceTapElement()
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 20.0))
        XCTAssertNotNil(statusView.label.range(of: "complete!"))
    }
    
    func testAllIntegrationMethods() throws {
        for integrationMethod in IntegrationMethod.allCases {
            print("Testing \(integrationMethod.rawValue)")
            switch integrationMethod {
            case .iDEAL, .giropay, .przelewy24, .bancontact, .eps, .afterpay, .sofort:
                testNoInputIntegrationMethod(integrationMethod, shouldConfirm: true)
            case .alipay:
                testAppToAppRedirect(integrationMethod)
            case .weChatPay:
//                testAppToAppRedirectWithoutReturnURL(integrationMethod)
                // TODO: WeChat Pay is currently unavailable
                break
            case .bacsDebit, .sepaDebit:
                testNoInputIntegrationMethod(integrationMethod, shouldConfirm: false)
            case .card, .cardSetupIntents, .fpx, .aubecsDebit, .applePay:
                // Tested in method-specific functions.
                break
            case .grabpay:
                // TODO: GrabPay is currently broken
                break
            case .oxxo:
                // TODO: OXXO is currently broken
                break
            }
        }
    }
    
    func testAUBECSDebit() {
        return
        // TODO: AU BECS Debit is broken in testmode.
        // The test BSB 000-000 doesn't work. https://stripe.com/docs/payments/au-becs-debit/accept-a-payment#web-test-integration
        //    self.popToMainMenu()
        //
        //    let tablesQuery = app.tables
        //    let rowForPaymentMethod = tablesQuery.cells["AU BECS Debit"]
        //    rowForPaymentMethod.tap()
        //
        //    XCUIApplication().tables/*@START_MENU_TOKEN@*/.buttons["AU BECS Debit"]/*[[".cells[\"AU BECS Debit\"].buttons[\"AU BECS Debit\"]",".buttons[\"AU BECS Debit\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        //
        //    let nameField = app.textFields["Full name"]
        //    XCTAssertTrue(nameField.waitForExistence(timeout: 10.0))
        //    nameField.tap()
        //    nameField.typeText("Name Nameson")
        //    let emailField = app.textFields["Email"]
        //    emailField.tap()
        //    emailField.typeText("name@example.com")
        //    let bsbField = app.textFields["BSB"]
        //    bsbField.tap()
        //    bsbField.typeText("000000")
        //    let accountNumberField = app.textFields["Account number"]
        //    accountNumberField.tap()
        //    accountNumberField.typeText("000123456")
        //    let buyButton = app.buttons["Buy"]
        //    XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        //    buyButton.forceTapElement()
        //
        //    let webViewsQuery = app.webViews
        //    let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        //    XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        //    completeAuth.forceTapElement()
        //
        //    let statusView = app.staticTexts["Payment status view"]
        //    XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        //    XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
    
    func testOxxo() {
        self.popToMainMenu()
        
        let tablesQuery = app.tables
        let rowForPaymentMethod = tablesQuery.cells["OXXO"]
        rowForPaymentMethod.scrollToAndTap(in: app)
        
        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        
        let webView = app.webViews.firstMatch
        XCTAssert(webView.waitForExistence(timeout: 10))
        let closeButton = app.buttons["Close"]
        XCTAssert(closeButton.waitForExistence(timeout: 10))
        closeButton.forceTapElement()
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
    
    func testFPX() {
        self.popToMainMenu()
        
        let tablesQuery = app.tables
        let rowForPaymentMethod = tablesQuery.cells["FPX"]
        rowForPaymentMethod.scrollToAndTap(in: app)
        
        let maybank = tablesQuery.staticTexts["Maybank2U"]
        XCTAssertTrue(maybank.waitForExistence(timeout: 60.0))
        maybank.tap()
        
        let webViewsQuery = app.webViews
        let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.forceTapElement()
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
    
    func testNoInputIntegrationMethod(_ integrationMethod: IntegrationMethod, shouldConfirm: Bool) {
        self.popToMainMenu()
        let tablesQuery = app.tables
        
        let rowForPaymentMethod = tablesQuery.cells[integrationMethod.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)
        
        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        if shouldConfirm {
            let webViewsQuery = app.webViews
            // Sometimes this is a Button, sometimes it's a StaticText. ¯\_(ツ)_/¯
            let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
            XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
            completeAuth.forceTapElement()
        }
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
    
    func testAppToAppRedirect(_ integrationMethod: IntegrationMethod) {
        self.popToMainMenu()
        let tablesQuery = app.tables
        
        let rowForPaymentMethod = tablesQuery.cells[integrationMethod.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)
        
        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10)) // wait for Safari to open
        let webViewsQuery = safari.webViews
        // Sometimes this is a Button, sometimes it's a StaticText. ¯\_(ツ)_/¯
        let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.forceTapElement()
        
        let safariOpenButton = safari.buttons["Open"]
        XCTAssertTrue(safariOpenButton.waitForExistence(timeout: 5.0))
        if safariOpenButton.exists {
            safariOpenButton.tap()
        }
        
        _ = app.wait(for: .runningForeground, timeout: 10) // wait to switch back to IntegrationTester
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
    
    func testAppToAppRedirectWithoutReturnURL(_ integrationMethod: IntegrationMethod) {
        self.popToMainMenu()
        let tablesQuery = app.tables
        
        let rowForPaymentMethod = tablesQuery.cells[integrationMethod.rawValue]
        rowForPaymentMethod.scrollToAndTap(in: app)
        
        let buyButton = app.buttons["Buy"]
        XCTAssertTrue(buyButton.waitForExistence(timeout: 10.0))
        buyButton.forceTapElement()
        
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 10)) // wait for Safari to open
        let webViewsQuery = safari.webViews
        // Sometimes this is a Button, sometimes it's a StaticText. ¯\_(ツ)_/¯
        let completeAuth = webViewsQuery.descendants(matching: .any)["AUTHORIZE TEST PAYMENT"].firstMatch
        XCTAssertTrue(completeAuth.waitForExistence(timeout: 60.0))
        completeAuth.forceTapElement()
        
        let successful = webViewsQuery.descendants(matching: .any)["Payment successful"].firstMatch
        XCTAssertTrue(successful.waitForExistence(timeout: 60.0))
        
        sleep(2) // Allow some time for the PaymentIntent state to update on the backend (RUN_MOBILESDK-288)
        
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: 10) // wait to switch back to IntegrationTester
        
        let statusView = app.staticTexts["Payment status view"]
        XCTAssertTrue(statusView.waitForExistence(timeout: 10.0))
        XCTAssertNotNil(statusView.label.range(of: "Payment complete"))
    }
}


// There seems to be an issue with our SwiftUI buttons - XCTest fails to scroll to the button's position.
// Work around this by targeting a coordinate inside the button.
// https://stackoverflow.com/questions/33422681/xcode-ui-test-ui-testing-failure-failed-to-scroll-to-visible-by-ax-action
extension XCUIElement {
    func forceTapElement() {
        // Tap the middle of the element.
        // (Sometimes the edges of rounded buttons aren't tappable in certain web elements.)
        let coordinate: XCUICoordinate = self.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
    
    func scrollToAndTap(in app: XCUIApplication) {
        while !self.exists {
            app.swipeUp()
        }
        self.tap()
    }
}
