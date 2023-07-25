//
//  PaymentSheet+LPMTests.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 7/18/23.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripeUICore

final class PaymentSheet_LPMTests: XCTestCase {
    let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    lazy var paymentHandler: STPPaymentHandler = {
        return STPPaymentHandler(
            apiClient: apiClient,
            formSpecPaymentHandler: PaymentSheetFormSpecPaymentHandler()
        )
    }()
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.allowsDelayedPaymentMethods = true
        config.returnURL = "https://foo.com"
        config.allowsPaymentMethodsRequiringShippingAddress = true
        return config
    }()

    override func setUp() async throws {
        await PaymentSheetLoader.loadMiscellaneousSingletons()
    }

    @MainActor
    func testSEPADebitConfirmFlows() async throws {
        try await _testConfirm(intentKinds: [.paymentIntent, .paymentIntentWithSetupFutureUsage, .setupIntent], currency: "EUR", paymentMethodType: .dynamic("sepa_debit")) { form in
            form.getTextFieldElement("Full name")?.setText("Foo")
            form.getTextFieldElement("Email")?.setText("f@z.c")
            form.getTextFieldElement("IBAN")?.setText("DE89370400440532013000")
            form.getTextFieldElement("Address line 1")?.setText("asdf")
            form.getTextFieldElement("City")?.setText("asdf")
            form.getTextFieldElement("ZIP")?.setText("12345")
            XCTAssertNotNil(form.getMandateElement())
        }
    }
}

// MARK: - Helper methods
extension PaymentSheet_LPMTests {
    enum IntentKind: CaseIterable {
        case paymentIntent
        case paymentIntentWithSetupFutureUsage
        case setupIntent
    }

    func _testConfirm(intentKinds: [IntentKind], currency: String, paymentMethodType: PaymentSheet.PaymentMethodType, formCompleter: (PaymentMethodElement) -> Void) async throws {
        for intentKind in intentKinds {
            try await _testConfirm(intentKind: intentKind, currency: currency, paymentMethodType: paymentMethodType, formCompleter: formCompleter)
        }
    }

    /// A helper method that tests three confirmation flows successfully complete:
    /// 1. normal" client-side confirmation
    /// 2. deferred client-side confirmation
    /// 3. deferred server-side
    /// - Parameter intentKind: Which kind of Intent you want to test.
    /// - Parameter currency: A valid currency for the payment method you're testing
    /// - Parameter paymentMethodType: The payment method type you're testing
    /// - Parameter formCompleter: A closure that takes the form for your payment method. Your implementaiton should fill in the form's textfields etc. You can also perform additional checks e.g. to ensure certain fields are shown/hidden.
    @MainActor
    func _testConfirm(intentKind: IntentKind, currency: String, paymentMethodType: PaymentSheet.PaymentMethodType, formCompleter: (PaymentMethodElement) -> Void) async throws {
        func makeDeferredIntent(_ intentConfig: PaymentSheet.IntentConfiguration) -> Intent {
            return .deferredIntent(elementsSession: ._testCardValue(), intentConfig: intentConfig)
        }
        let paymentMethodString = PaymentSheet.PaymentMethodType.string(from: paymentMethodType)!
        let intents: [(String, Intent)]
        let mandateDataParamsForServerSideConfirmation: [String: Any] = [ // We require merchants to set this themselves for server-side confirmation
            "mandate_data": [
                "customer_acceptance": [
                    "type": "online",
                    "online": [
                        "user_agent": "123",
                        "ip_address": "172.18.117.125",
                    ],
                ] as [String: Any],
            ],
        ]
        switch intentKind {
        case .paymentIntent:
            let paymentIntent: STPPaymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: [paymentMethodString])
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: [paymentMethodString])
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { paymentMethod, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: [paymentMethodString], paymentMethodID: paymentMethod.stripeId, confirm: true, otherParams: mandateDataParamsForServerSideConfirmation)
            }
            intents = [
                ("PaymentIntent", .paymentIntent(paymentIntent)),
                ("Deferred PaymentIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred PaymentIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        case .paymentIntentWithSetupFutureUsage:
            let paymentIntent: STPPaymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(types: [paymentMethodString], otherParams: ["setup_future_usage": "off_session"])
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency, setupFutureUsage: .offSession)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: [paymentMethodString], otherParams: ["setup_future_usage": "off_session"])
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency, setupFutureUsage: .offSession)) { paymentMethod, _ in
                let otherParams = [
                    "setup_future_usage": "off_session",
                ].merging(mandateDataParamsForServerSideConfirmation) { _, b in b }
                return try await STPTestingAPIClient.shared.fetchPaymentIntent(types: [paymentMethodString], paymentMethodID: paymentMethod.stripeId, confirm: true, otherParams: otherParams)
            }
            intents = [
                ("PaymentIntent", .paymentIntent(paymentIntent)),
                ("Deferred PaymentIntent w/ setup_future_usage - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred PaymentIntent w/ setup_future_usage - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        case .setupIntent:
            let setupIntent: STPSetupIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: [paymentMethodString])
                return try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            }()
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { _, _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: [paymentMethodString])
            }
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { paymentMethod, _ in
                return try await STPTestingAPIClient.shared.fetchSetupIntent(types: [paymentMethodString], paymentMethodID: paymentMethod.stripeId, confirm: true, otherParams: mandateDataParamsForServerSideConfirmation)
            }
            intents = [
                ("SetupIntent", .setupIntent(setupIntent)),
                ("Deferred SetupIntent - client side confirmation", makeDeferredIntent(deferredCSC)),
                ("Deferred SetupIntent - server side confirmation", makeDeferredIntent(deferredSSC)),
            ]
        }
        for (description, intent) in intents {
            // Make the form
            let formFactory = PaymentSheetFormFactory(intent: intent, configuration: .paymentSheet(configuration), paymentMethod: paymentMethodType)
            let paymentMethodForm = formFactory.make()
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1000))
            view.addAndPinSubview(paymentMethodForm.view)

            // Fill out the form
            sendEventToSubviews(.viewDidAppear, from: paymentMethodForm.view) // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
            formCompleter(paymentMethodForm)

            // Generate params from the form
            guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: paymentMethodType)) else {
                XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
                return
            }
            let e = expectation(description: "Confirm")
            paymentHandler._redirectShim = { _, _, _ in
                // This gets called instead of the PaymentSheet.confirm callback if the Intent is successfully confirmed and requires next actions.
                print("✅ \(description): Successfully confirmed the intent. Its status is now requires_action.")
                e.fulfill()
            }
            // Confirm the intent with the form details
            PaymentSheet.confirm(
                configuration: configuration,
                authenticationContext: self,
                intent: intent,
                paymentOption: .new(confirmParams: intentConfirmParams),
                paymentHandler: paymentHandler
            ) { result, _  in
                e.fulfill()
                switch result {
                case .failed(error: let error):
                    XCTFail("❌ \(description): PaymentSheet.confirm failed - \(error)")
                case .canceled:
                    XCTFail("❌ \(description): PaymentSheet.confirm canceled!")
                case .completed:
                    print("✅ \(description): PaymentSheet.confirm completed")
                }
            }
            await fulfillment(of: [e], timeout: 5)
        }
    }
}

extension PaymentSheet_LPMTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
