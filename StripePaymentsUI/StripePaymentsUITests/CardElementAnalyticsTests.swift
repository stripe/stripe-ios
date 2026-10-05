//
//  CardElementAnalyticsTests.swift
//  StripePaymentsUITests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) @testable import StripePaymentsUI
import UIKit
import XCTest

class CardElementAnalyticsTests: XCTestCase {
    private let analyticsClient = MockAnalyticsClient()

    func testInitializationDoesNotReportEvents() {
        let field = STPPaymentCardTextField()
        let form = STPCardFormView()
        XCTAssertTrue(field.cardElementAnalytics.reportedEvents.isEmpty)
        XCTAssertTrue(form.cardElementAnalytics.reportedEvents.isEmpty)
    }

    func testDefaultClientIncludesSharedPaymentMetadata() {
        let client = STPAnalyticsClient.sharedClient
        let initialEventCount = client._testLogHistory.count
        let field = STPPaymentCardTextField()
        let form = STPCardFormView()
        let window = UIWindow()

        window.addSubview(field)
        window.addSubview(form)

        let payloads = client._testLogHistory.dropFirst(initialEventCount).filter {
            $0["event"] as? String == STPAnalyticEvent.mobileCardElementShown.rawValue
        }
        XCTAssertEqual(payloads.count, 2)
        XCTAssertEqual(payloads.compactMap { $0["widget_type"] as? String }, ["payment_card_text_field", "card_form_view"])
        for payload in payloads {
            XCTAssertEqual(payload["publishable_key"] as? String, STPAPIClient.shared.sanitizedPublishableKey ?? "unknown")
            XCTAssertEqual(payload["session_id"] as? String, AnalyticsHelper.shared.sessionID)
            XCTAssertEqual(payload["product_usage"] as? [String], client.productUsage.sorted())
            XCTAssertEqual(payload["pay_var"] as? String, "payments-ui")
            XCTAssertNotNil(payload["apple_pay_enabled"] as? NSNumber)
            XCTAssertEqual(payload["ocr_type"] as? String, PaymentsSDKVariant.ocrTypeString)
        }
    }

    func testShownOnlyOnceWhenAttachedToWindow() {
        let widgets = makeWidgets()
        let container = UIView()
        widgets.forEach { container.addSubview($0.view) }
        XCTAssertTrue(analyticsClient.loggedAnalytics.isEmpty)

        // When the controls enter a window, leave it, and enter another window
        let firstWindow = UIWindow()
        firstWindow.addSubview(container)
        container.removeFromSuperview()
        let secondWindow = UIWindow()
        secondWindow.addSubview(container)

        // Then each control reports only one shown event with its widget type
        assertEvents(.mobileCardElementShown, widgetTypes: ["payment_card_text_field", "card_form_view"])
        XCTAssertEqual(analyticsClient.loggedAnalytics.count, 2)
    }

    func testNewInstancesReportShownIndependently() {
        let window = UIWindow()
        for _ in 0..<2 {
            makeWidgets().forEach { window.addSubview($0.view) }
        }

        assertEvents(.mobileCardElementShown, widgetTypes: [
            "payment_card_text_field", "card_form_view", "payment_card_text_field", "card_form_view",
        ])
    }

    func testFocusReportsInteractionOnlyOnceAcrossFields() {
        let window = UIWindow()
        let viewController = UIViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        for widget in makeWidgets() {
            viewController.view.addSubview(widget.view)
            for field in widget.fields {
                XCTAssertTrue(field.becomeFirstResponder())
                sendActions(from: field, for: .editingDidBegin)
                field.resignFirstResponder()
            }
        }

        assertEvents(.mobileCardElementInteraction, widgetTypes: ["payment_card_text_field", "card_form_view"])
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: [])
    }

    func testTextChangesReportInteractionWithoutFocus() {
        for widget in makeWidgets() {
            widget.fields[0].text = "4"
            sendActions(from: widget.fields[0], for: .editingChanged)
            widget.fields[0].text = "42"
            sendActions(from: widget.fields[0], for: .editingChanged)
        }

        assertEvents(.mobileCardElementInteraction, widgetTypes: ["payment_card_text_field", "card_form_view"])
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: [])
    }

    func testPaymentCardTextFieldCompletionRequiresAllFieldsAndReportsOnlyOnce() {
        let field = makePaymentCardTextField()
        field.countryCode = "US"
        field.postalCodeEntryEnabled = true

        field.numberField.text = "4242424242424242"
        field.expirationField.text = "1250"
        field.cvcField.text = "123"
        XCTAssertFalse(field.isValid)
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: [])

        field.postalCodeField.text = "94103"
        XCTAssertTrue(field.isValid)
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: ["payment_card_text_field"])

        // When the user invalidates, completes, clears, and completes the form again
        field.cvcField.text = "1"
        XCTAssertFalse(field.isValid)
        field.cvcField.text = "123"
        field.clear()
        field.numberField.text = "4242424242424242"
        field.expirationField.text = "1250"
        field.cvcField.text = "123"
        field.postalCodeField.text = "94103"
        XCTAssertTrue(field.isValid)

        // Then interaction and completion remain deduplicated
        assertEvents(.mobileCardElementInteraction, widgetTypes: ["payment_card_text_field"])
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: ["payment_card_text_field"])
    }

    func testCardFormCompletionRequiresAllFieldsAndReportsOnlyOnce() {
        let form = makeCardFormView()
        form.countryField.select(countryCode: "US")
        form.numberField.text = "4242424242424242"
        sendActions(from: form.numberField, for: .editingChanged)
        form.expiryField.text = "1250"
        form.cvcField.text = "123"
        XCTAssertNil(form.cardParams)
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: [])

        form.postalCodeField.text = "94103"
        XCTAssertNotNil(form.cardParams)
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: ["card_form_view"])

        form.cvcField.text = "1"
        XCTAssertNil(form.cardParams)
        form.cvcField.text = "123"
        XCTAssertNotNil(form.cardParams)

        assertEvents(.mobileCardElementInteraction, widgetTypes: ["card_form_view"])
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: ["card_form_view"])
    }

    func testValidationChangesAloneDoNotReportInteraction() {
        let form = makeCardFormView()
        form.countryCode = "US"
        form.countryCode = "HK"
        form.numberField.validator.validationState = .invalid(errorMessage: "Invalid card number")

        assertEvents(.mobileCardElementInteraction, widgetTypes: [])
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: [])
    }

    func testCompletionWithPostalCodeDisabledOrNotRequired() {
        let field = makePaymentCardTextField()
        field.postalCodeEntryEnabled = false
        field.numberField.text = "4242424242424242"
        field.expirationField.text = "1250"
        field.cvcField.text = "123"
        XCTAssertTrue(field.isValid)

        let form = makeCardFormView()
        form.countryField.select(countryCode: "HK")
        form.numberField.text = "4242424242424242"
        form.expiryField.text = "1250"
        form.cvcField.text = "123"
        XCTAssertNotNil(form.cardParams)

        assertEvents(.mobileCardElementFormCompleted, widgetTypes: ["payment_card_text_field", "card_form_view"])
    }

    func testChangingCountryCanCompleteCardForm() {
        // Given valid card details and a country that requires a postal code
        let form = makeCardFormView()
        form.countryField.select(countryCode: "US")
        form.numberField.text = "4242424242424242"
        form.expiryField.text = "1250"
        form.cvcField.text = "123"
        XCTAssertNil(form.cardParams)
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: [])

        // When the user switches to a country without postal codes
        form.countryField.select(countryCode: "HK")

        // Then the form reports completion even though the country was valid before
        XCTAssertNotNil(form.cardParams)
        assertEvents(.mobileCardElementFormCompleted, widgetTypes: ["card_form_view"])
    }

    private func makePaymentCardTextField() -> STPPaymentCardTextField {
        let field = STPPaymentCardTextField(frame: CGRect(x: 0, y: 0, width: 400, height: 50))
        field.cbcEnabledOverride = false
        field.cardElementAnalytics = CardElementAnalytics(widgetType: .paymentCardTextField, analyticsClient: analyticsClient)
        return field
    }

    private func makeCardFormView() -> STPCardFormView {
        let form = STPCardFormView(billingAddressCollection: .automatic, cbcEnabledOverride: false)
        form.cardElementAnalytics = CardElementAnalytics(widgetType: .cardFormView, analyticsClient: analyticsClient)
        return form
    }

    private func makeWidgets() -> [(view: UIView, fields: [UITextField])] {
        let field = makePaymentCardTextField()
        let form = makeCardFormView()
        return [
            (field, [field.numberField, field.expirationField, field.cvcField, field.postalCodeField]),
            (form, [form.numberField, form.expiryField, form.cvcField, form.countryField, form.postalCodeField]),
        ]
    }

    private func assertEvents(
        _ event: STPAnalyticEvent,
        widgetTypes: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let analytics = analyticsClient.loggedAnalytics.filter { $0.event == event }
        XCTAssertEqual(analytics.compactMap { $0.params["widget_type"] as? String }, widgetTypes, file: file, line: line)
    }

    private func sendActions(from control: UIControl, for event: UIControl.Event) {
        // These tests run without a host app, so UIControl cannot dispatch through UIApplication.
        for target in control.allTargets {
            for action in control.actions(forTarget: target, forControlEvent: event) ?? [] {
                _ = (target as? NSObject)?.perform(NSSelectorFromString(action), with: control)
            }
        }
    }
}
