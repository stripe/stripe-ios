//
//  PaymentSheetDeferredUIBankAccountTests.swift
//  PaymentSheet Example
//
//  Created by David Estes on 2/11/26.
//

import XCTest

class PaymentSheetDeferredUIBankAccountTests: PaymentSheetUITestCase {
    func testDeferredIntentPaymentIntent_USBankAccount_ClientSideConfirmation() {
        _testUSBankAccount(mode: .payment, integrationType: .deferred_csc)
    }

    func testDeferredIntentPaymentIntent_USBankAccount_ServerSideConfirmation() {
        _testUSBankAccount(mode: .payment, integrationType: .deferred_ssc)
    }

    func testDeferredIntentSetupIntent_USBankAccount_ClientSideConfirmation() {
        _testUSBankAccount(mode: .setup, integrationType: .deferred_csc)
    }

    func testDeferredIntentSetupIntent_USBankAccount_ServerSideConfirmation() {
        _testUSBankAccount(mode: .setup, integrationType: .deferred_ssc)
    }

    /* Disable Link test
     func testDeferredIntentLinkSignIn_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try loginAndPay()
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkSignIn_ClientSideConfirmation_LostCardDecline() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     app.buttons["Present PaymentSheet"].tap()
     
     let payWithLinkButton = app.buttons["Pay with Link"]
     XCTAssertTrue(payWithLinkButton.waitForExistence(timeout: 10))
     payWithLinkButton.tap()
     
     try linkLogin()
     
     let modal = app.otherElements["Stripe.Link.PayWithLinkWebController"]
     let paymentMethodPicker = app.otherElements["Stripe.Link.PaymentMethodPicker"]
     if paymentMethodPicker.waitForExistence(timeout: 10) {
     paymentMethodPicker.tap()
     paymentMethodPicker.buttons["Add a payment method"].tap()
     }
     
     try fillCardData(app, container: modal, cardNumber: "4000000000009987")
     
     let payButton = modal.buttons["Pay $50.99"]
     expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: payButton, handler: nil)
     waitForExpectations(timeout: 10, handler: nil)
     payButton.tap()
     
     let failedText = modal.staticTexts["The payment failed."]
     XCTAssertTrue(failedText.waitForExistence(timeout: 10))
     }
     */
    /* Disable Link test
     func testDeferredIntentLinkFlowControllerFlow_ClientSideConfirmation() throws {
     loadPlayground(
     app,
     settings: [
     "customer_mode": "new",
     "automatic_payment_methods": "off",
     "link": "on",
     "init_mode": "Deferred",
     ]
     )
     
     let paymentMethodButton = app.buttons["Select Payment Method"]
     XCTAssertTrue(paymentMethodButton.waitForExistence(timeout: 10.0))
     paymentMethodButton.tap()
     
     let addCardButton = app.buttons["Link"]
     XCTAssertTrue(addCardButton.waitForExistence(timeout: 10.0))
     addCardButton.tap()
     
     app.buttons["Confirm"].tap()
     
     try loginAndPay()
     }
     */
}
