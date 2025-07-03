//
//  PaymentSheetExternalPaymentMethodTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/31/23.
//

import XCTest

@testable @_spi(STP) @_spi(CustomPaymentMethodsBeta) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore

@MainActor
final class PaymentSheetExternalPaymentMethodTests: XCTestCase {
    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    func testExternalPaymentMethodCallsConfirmHandler() async throws {
        let e = expectation(description: "Confirm completed")
        let e2 = expectation(description: "External PM confirm handler called")

        var configuration = PaymentSheet.Configuration()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { externalPaymentMethodType, _, completion in
            XCTAssertEqual(externalPaymentMethodType, "external_paypal")
            e2.fulfill()
            XCTAssertTrue(Thread.isMainThread)
            completion(.completed)
        })

        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in
            XCTFail("Intent confirm handler shouldn't be called")
        }))

        // Make the form
        let paymentMethodForm = makeForm(intent: intent, configuration: configuration)

        // External PMs display no fields
        XCTAssertEqual(paymentMethodForm.getAllUnwrappedSubElements().count, 1)

        // Confirm the intent with the form details
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: ._testCardValue(),
            paymentOption: .external(paymentMethod: ._testPayPalValue(configuration.externalPaymentMethodConfiguration!), billingDetails: .init()),
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

    func testExternalFormBillingDetails() async throws {
        let externalConfirmHandlerCalled = expectation(description: "External PM confirm handler called")
        var configuration = PaymentSheet.Configuration()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { externalPaymentMethodType, billingDetails, completion in
            XCTAssertEqual(externalPaymentMethodType, "external_paypal")
            // (2) ...and billing details collected in the form should be passed to the merchant's confirm handler
            XCTAssertEqual(billingDetails.name, "Jane Doe")
            XCTAssertEqual(billingDetails.phone, "+15551234567")
            XCTAssertEqual(billingDetails.address?.line1, "354 Oyster Point Blvd")
            XCTAssertEqual(billingDetails.address?.line2, "Apt 123")
            XCTAssertEqual(billingDetails.address?.city, "South San Francisco")
            XCTAssertEqual(billingDetails.address?.state, "CA")
            XCTAssertEqual(billingDetails.address?.postalCode, "94080")
            XCTAssertEqual(billingDetails.address?.country, "US")
            externalConfirmHandlerCalled.fulfill()
            completion(.completed)
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

        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in
            XCTFail("Intent confirm handler shouldn't be called")
        }))

        // (1) ...should result in the external payment method form showing billing detail fields pre-populated with default values...
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
        guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: .external(._testPayPalValue(configuration.externalPaymentMethodConfiguration!)))) else {
            XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
            return
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: ._testCardValue(),
            paymentOption: .external(paymentMethod: ._testPayPalValue(configuration.externalPaymentMethodConfiguration!), billingDetails: intentConfirmParams.paymentMethodParams.nonnil_billingDetails),
            paymentHandler: .shared(),
            analyticsHelper: ._testValue()
        ) { _, _ in }
        await fulfillment(of: [externalConfirmHandlerCalled], timeout: 5)
    }

    func testConfirmUsesMerchantConfirmHandlerResults() {
        struct MockError: Error, Equatable { }
        func _confirm(with merchantReturnedResult: PaymentSheetResult) {
            let e = expectation(description: "External PM confirm handler called")
            var configuration = PaymentSheet.Configuration()
            configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { _, _, completion in
                // The merchant's returned result should be passed back in `PaymentSheet.confirm`
                completion(merchantReturnedResult)
            })
            let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in
                XCTFail("Intent confirm handler shouldn't be called")
            }))
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: self,
                intent: intent,
                elementsSession: ._testCardValue(),
                paymentOption: .external(paymentMethod: ._testPayPalValue(configuration.externalPaymentMethodConfiguration!), billingDetails: .init()),
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
        let formFactory = PaymentSheetFormFactory(intent: intent, elementsSession: ._testCardValue(), configuration: .paymentElement(configuration), paymentMethod: .external(._testPayPalValue(configuration.externalPaymentMethodConfiguration!)))
        let paymentMethodForm = formFactory.make()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1000))
        view.addAndPinSubview(paymentMethodForm.view) // This gets rid of distracting autolayout warnings in the logs
        sendEventToSubviews(.viewDidAppear, from: paymentMethodForm.view) // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
        return paymentMethodForm
    }
}

extension PaymentSheetExternalPaymentMethodTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

extension ExternalPaymentOption {
    static func _testPayPalValue(_ config: PaymentSheet.ExternalPaymentMethodConfiguration) -> ExternalPaymentOption {
        let epm: ExternalPaymentMethod = .init(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://todo.com")!,
            darkImageUrl: URL(string: "https://todo.com")!
        )
        return .from(epm, configuration: config)!
    }
}
