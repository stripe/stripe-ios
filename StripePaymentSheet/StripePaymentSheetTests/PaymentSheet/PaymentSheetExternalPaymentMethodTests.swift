//
//  PaymentSheetExternalPaymentMethodTests.swift
//  StripePaymentSheetTests
//
//  Created by Yuki Tokuhiro on 8/31/23.
//

import XCTest

@testable @_spi(STP) import StripePaymentSheet
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
            paymentOption: .external(paymentMethod: ._testPayPalValue(), billingDetails: .init()),
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
            XCTAssertEqual(billingDetails.address?.state, "AL")
            XCTAssertEqual(billingDetails.address?.postalCode, "12345")
            XCTAssertEqual(billingDetails.address?.country, "US")
            externalConfirmHandlerCalled.fulfill()
            completion(.completed)
        })
        // Configuring PaymentSheet to collect full billing details...
        configuration.billingDetailsCollectionConfiguration.name = .always
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.billingDetailsCollectionConfiguration.phone = .always
        configuration.billingDetailsCollectionConfiguration.address = .full
        let intent = Intent.deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in
            XCTFail("Intent confirm handler shouldn't be called")
        }))

        // (1) ...should result in the external payment method form showing billing detail fields...
        let paymentMethodForm = makeForm(intent: intent, configuration: configuration)
        paymentMethodForm.getTextFieldElement("Full name")?.setText("Jane Doe") ?? XCTFail()
        paymentMethodForm.getTextFieldElement("Email")?.setText("foo@bar.com") ?? XCTFail()
        paymentMethodForm.getPhoneNumberElement()?.textFieldElement.setText("5551234567") ?? XCTFail()
        XCTAssertNotNil(paymentMethodForm.getDropdownFieldElement("Country or region"))
        paymentMethodForm.getTextFieldElement("Address line 1")?.setText("354 Oyster Point Blvd") ?? XCTFail()
        paymentMethodForm.getTextFieldElement("Address line 2")?.setText("Apt 123") ?? XCTFail()
        paymentMethodForm.getTextFieldElement("City")?.setText("South San Francisco") ?? XCTFail()
        XCTAssertNotNil(paymentMethodForm.getDropdownFieldElement("State"))
        paymentMethodForm.getTextFieldElement("ZIP")?.setText("12345") ?? XCTFail()

        // Simulate customer tapping "Buy" - generate params from the form and confirm payment
        guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: .external(._testPayPalValue()))) else {
            XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
            return
        }
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: ._testCardValue(),
            paymentOption: .external(paymentMethod: ._testPayPalValue(), billingDetails: intentConfirmParams.paymentMethodParams.nonnil_billingDetails),
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
                paymentOption: .external(paymentMethod: ._testPayPalValue(), billingDetails: .init()),
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
        let formFactory = PaymentSheetFormFactory(intent: intent, elementsSession: ._testCardValue(), configuration: .paymentSheet(configuration), paymentMethod: .external(._testPayPalValue()))
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

extension ExternalPaymentMethod {
    static func _testPayPalValue() -> ExternalPaymentMethod {
        return .init(
            type: "external_paypal",
            label: "PayPal",
            lightImageUrl: URL(string: "https://todo.com")!,
            darkImageUrl: URL(string: "https://todo.com")!
        )
    }
}
