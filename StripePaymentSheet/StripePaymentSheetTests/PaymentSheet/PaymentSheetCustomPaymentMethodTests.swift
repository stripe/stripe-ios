//
//  PaymentSheetCustomPaymentMethodTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 4/1/25.
//

import Foundation
import XCTest

@testable @_spi(STP) @_spi(CustomPaymentMethodsBeta) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore

@MainActor
final class PaymentSheetCustomPaymentMethodTests: XCTestCase {

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    func testCustomPaymentMethodCallsConfirmHandler() async throws {
        let e = expectation(description: "Confirm completed")
        let e2 = expectation(description: "Custom PM confirm handler called")

        let testCPM = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_1Qzj4rFY0qyl6XeWoHB842bf")

        var configuration = PaymentSheet.Configuration()
        configuration.customPaymentMethodConfiguration = .init(customPaymentMethods: [testCPM], customPaymentMethodConfirmHandler: { customPaymentMethodType, _ in
            XCTAssertEqual(customPaymentMethodType.id, "cpmt_1Qzj4rFY0qyl6XeWoHB842bf")
            e2.fulfill()
            XCTAssertTrue(Thread.isMainThread)
            return .completed
        })

        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _ in
            XCTFail("Intent confirm handler shouldn't be called")
            return ""
        }))

        // Make the form
        let paymentMethodForm = makeForm(intent: intent, configuration: configuration)

        // Custom PMs display no fields
        XCTAssertEqual(paymentMethodForm.getAllUnwrappedSubElements().count, 1)

        // Confirm the intent with the form details
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: ._testCardValue(),
            paymentOption: .external(paymentMethod: ._testBufoPayValue(configuration.customPaymentMethodConfiguration!), billingDetails: .init()),
            paymentHandler: .shared(),
            analyticsHelper: ._testValue()
        ) { result, analyticsConfirmType in
            e.fulfill()
            guard case .completed = result else {
                XCTFail()
                return
            }
            XCTAssertEqual(analyticsConfirmType, nil)
        }
        await fulfillment(of: [e, e2], timeout: 5)
    }

    func testCustomFormBillingDetails() async throws {
        let customConfirmHandlerCalled = expectation(description: "Custom PM confirm handler called")

        var testCPM = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_1Qzj4rFY0qyl6XeWoHB842bf")
        testCPM.disableBillingDetailCollection = false

        var configuration = PaymentSheet.Configuration()
        configuration.customPaymentMethodConfiguration = .init(customPaymentMethods: [testCPM], customPaymentMethodConfirmHandler: { customPaymentMethodType, billingDetails in
            XCTAssertEqual(customPaymentMethodType.id, "cpmt_1Qzj4rFY0qyl6XeWoHB842bf")
            // (2) ...and billing details collected in the form should be passed to the merchant's confirm handler
            XCTAssertEqual(billingDetails.name, "Jane Doe")
            XCTAssertEqual(billingDetails.phone, "+15551234567")
            XCTAssertEqual(billingDetails.address?.line1, "354 Oyster Point Blvd")
            XCTAssertEqual(billingDetails.address?.line2, "Apt 123")
            XCTAssertEqual(billingDetails.address?.city, "South San Francisco")
            XCTAssertEqual(billingDetails.address?.state, "CA")
            XCTAssertEqual(billingDetails.address?.postalCode, "94080")
            XCTAssertEqual(billingDetails.address?.country, "US")
            customConfirmHandlerCalled.fulfill()
            return .completed
        })

        // Configuring PaymentSheet to collect full billing details with default values...
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        configuration.defaultBillingDetails = PaymentSheet.BillingDetails(
            address: PaymentSheet.Address(
                city: "South San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                line2: "Apt 123",
                postalCode: "94080",
                state: "CA"
            ),
            email: "foo@bar.com",
            name: "Jane Doe",
            phone: "+15551234567"
        )

        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _ in
            XCTFail("Intent confirm handler shouldn't be called")
            return ""
        }))

        // (1) ...should result in the custom payment method form showing billing detail fields pre-populated with default values...
        let paymentMethodForm = makeForm(intent: intent, configuration: configuration)
        XCTAssertEqual(paymentMethodForm.getTextFieldElement("Full name")?.text, "Jane Doe")
        XCTAssertEqual(paymentMethodForm.getTextFieldElement("Email")?.text, "foo@bar.com")
        XCTAssertEqual(paymentMethodForm.getPhoneNumberElement()?.phoneNumber?.string(as: .e164), "+15551234567")
        XCTAssertNotNil(paymentMethodForm.getDropdownFieldElement("Country or region"))
        XCTAssertEqual(paymentMethodForm.getTextFieldElement("Address line 1")?.text, "354 Oyster Point Blvd")
        XCTAssertEqual(paymentMethodForm.getTextFieldElement("Address line 2")?.text, "Apt 123")
        XCTAssertEqual(paymentMethodForm.getTextFieldElement("City")?.text, "South San Francisco")
        XCTAssertNotNil(paymentMethodForm.getDropdownFieldElement("State"))
        XCTAssertEqual(paymentMethodForm.getTextFieldElement("ZIP")?.text, "94080")

        // Simulate customer tapping "Buy" - generate params from the form and confirm payment
        guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: .external(._testBufoPayValue(configuration.customPaymentMethodConfiguration!)))) else {
            XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
            return
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: ._testCardValue(),
            paymentOption: .external(paymentMethod: ._testBufoPayValue(configuration.customPaymentMethodConfiguration!), billingDetails: intentConfirmParams.paymentMethodParams.nonnil_billingDetails),
            paymentHandler: .shared(),
            analyticsHelper: ._testValue()
        ) { _, _ in }
        await fulfillment(of: [customConfirmHandlerCalled], timeout: 5)
    }

    func testConfirmUsesMerchantConfirmHandlerResults() {
        struct MockError: Error, Equatable { }
        func _confirm(with merchantReturnedResult: PaymentSheetResult) {
            let e = expectation(description: "Custom PM confirm handler called")

            let testCPM = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_1Qzj4rFY0qyl6XeWoHB842bf")
            var configuration = PaymentSheet.Configuration()
            configuration.customPaymentMethodConfiguration = .init(customPaymentMethods: [testCPM], customPaymentMethodConfirmHandler: { _, _ in
                // The merchant's returned result should be passed back in `PaymentSheet.confirm`
                return merchantReturnedResult
            })
            let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _ in
                XCTFail("Intent confirm handler shouldn't be called")
                return ""
            }))
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: self,
                intent: intent,
                elementsSession: ._testCardValue(),
                paymentOption: .external(paymentMethod: ._testBufoPayValue(configuration.customPaymentMethodConfiguration!), billingDetails: .init()),
                paymentHandler: .shared(),
                analyticsHelper: ._testValue()
            ) { result, analyticsConfirmType in
                e.fulfill()
                XCTAssertEqual(analyticsConfirmType, nil)
                switch (result, merchantReturnedResult) {
                case (.canceled, .canceled), (.completed, .completed):
                    break
                case let (.failed(actualError), .failed(expectedError)):
                    guard let actualError = actualError as? MockError, let expectedError = expectedError as? MockError else {
                        XCTFail()
                        return
                    }
                    XCTAssertEqual(actualError, expectedError)
                default:
                    XCTFail()
                }
            }
            waitForExpectations(timeout: 1)
        }

        _confirm(with: .canceled)
        _confirm(with: .completed)
        _confirm(with: .failed(error: MockError()))
    }

    func makeForm(intent: Intent, configuration: PaymentSheet.Configuration) -> PaymentMethodElement {
        let formFactory = PaymentSheetFormFactory(intent: intent, elementsSession: ._testCardValue(), configuration: .paymentElement(configuration), paymentMethod: .external(._testBufoPayValue(configuration.customPaymentMethodConfiguration!)))
        let paymentMethodForm = formFactory.make()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1000))
        view.addAndPinSubview(paymentMethodForm.view) // This gets rid of distracting autolayout warnings in the logs
        sendEventToSubviews(.viewDidAppear, from: paymentMethodForm.view) // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
        return paymentMethodForm
    }
}

extension PaymentSheetCustomPaymentMethodTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

extension ExternalPaymentOption {
    static func _testBufoPayValue(_ config: PaymentSheet.CustomPaymentMethodConfiguration? = nil) -> ExternalPaymentOption {
        let cpm = PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethod(id: "cpmt_1Qzj4rFY0qyl6XeWoHB842bf", subtitle: "Pay now with BufoPay")
        let config = {
            if let config {
                return config
            }

            return PaymentSheet.CustomPaymentMethodConfiguration(customPaymentMethods: [cpm]) { _, _ in
                XCTFail("CPM confirm handler should not be called in these tests.")
                return .canceled
            }
        }()

        let elementsSessionCPM: CustomPaymentMethod = .init(
            displayName: "Bufo Pay",
            type: cpm.id,
            logoUrl: URL(string: "https://stripe-camo.global.ssl.fastly.net/57bf89f1261bca3624e52be020e6472d2ab0d339330c9cb09eb5e4a9e1e05616/68747470733a2f2f66696c65732e7374726970652e636f6d2f66696c65732f4d44423859574e6a6446387853485a555354644d645456764d3141784f46707766475a666447567a64463931597a4a515a484d77626d68584e3156696330564b4e5563314e48704452455530306c6b567a51496332")!,
            isPreset: false,
            error: nil)

        return .from(elementsSessionCPM, configuration: config)!
    }
}
