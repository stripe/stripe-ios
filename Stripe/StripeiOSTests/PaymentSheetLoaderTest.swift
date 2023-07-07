//
//  PaymentSheetLoaderTest.swift
//  StripeiOSTests
//
//  Created by Yuki Tokuhiro on 6/24/23.
//

@testable @_spi(STP) import StripePaymentSheet
import XCTest

final class PaymentSheetLoaderTest: XCTestCase {
    let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        return config
    }()

    func testPaymentSheetLoadWithSetupIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Setup Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card, .iDEAL, .bancontact, .sofort]
        STPTestingAPIClient.shared.fetchSetupIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheetLoader.load(
                    mode: .setupIntentClientSecret(clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success(let setupIntent, let paymentMethods, _):
                        XCTAssertEqual(
                            Set(setupIntent.recommendedPaymentMethodTypes),
                            Set(expected)
                        )
                        XCTAssertEqual(paymentMethods, [])
                        expectation.fulfill()
                    case .failure(let error):
                        print(error)
                    }
                }

            case .failure(let error):
                print(error)
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithSetupIntentAttachedPaymentMethod() {
        let expectation = XCTestExpectation(
            description: "Load SetupIntent with an attached payment method"
        )
        STPTestingAPIClient.shared().createSetupIntent(withParams: [
            "payment_method": "pm_card_visa",
        ]) { clientSecret, error in
            guard let clientSecret = clientSecret, error == nil else {
                XCTFail()
                expectation.fulfill()
                return
            }

            PaymentSheetLoader.load(
                mode: .setupIntentClientSecret(clientSecret),
                configuration: self.configuration
            ) { result in
                defer { expectation.fulfill() }
                guard case .success = result else {
                    XCTFail()
                    return
                }
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadDeferredIntentSucceeds() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheetLoader.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfigTestcases: [PaymentSheet.IntentConfiguration] = [
            // Typical auto pm payment config
            .init(mode: .payment(amount: 1000, currency: "USD"), confirmHandler: confirmHandler),
            // Payment config with explicit PM types
            .init(mode: .payment(amount: 1000, currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler),
            // Typical auto pm setup config
            .init(mode: .setup(currency: "USD"), confirmHandler: confirmHandler),
            // Setup config with explicit PM types
            .init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler),
            // Setup config w/o currency
            .init(mode: .setup(), confirmHandler: confirmHandler),
        ]
        loadExpectation.expectedFulfillmentCount = intentConfigTestcases.count
        for (index, intentConfig) in intentConfigTestcases.enumerated() {
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: self.configuration) { result in
                loadExpectation.fulfill()
                switch result {
                case .success(let intent, _, _):
                    guard case .deferredIntent = intent else {
                        XCTFail()
                        return
                    }
                case .failure(let error):
                    XCTFail("Test case at index \(index) failed: \(error)")
                    print(error)
                }
            }
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadDeferredIntentFails() {
        let loadExpectation = XCTestExpectation(description: "Load PaymentSheet")
        // Test PaymentSheetLoader.load can load various IntentConfigurations
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = {_, _, _ in
            XCTFail("Confirm handler shouldn't be called.")
        }
        let intentConfigTestcases: [PaymentSheet.IntentConfiguration] = [
            // Bad currency
            .init(mode: .payment(amount: 1000, currency: "FOO"), confirmHandler: confirmHandler),
            // Bad amount
            .init(mode: .payment(amount: 0, currency: "USD"), paymentMethodTypes: ["card"], confirmHandler: confirmHandler),
            // Bad pm type
            .init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card", "foo"], confirmHandler: confirmHandler),
            // Bad OBO
            .init(mode: .setup(currency: "USD"), paymentMethodTypes: ["card"], onBehalfOf: "foo", confirmHandler: confirmHandler),
        ]
        loadExpectation.expectedFulfillmentCount = intentConfigTestcases.count
        for (index, intentConfig) in intentConfigTestcases.enumerated() {
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: self.configuration) { result in
                loadExpectation.fulfill()
                switch result {
                case .success:
                    XCTFail("Test case at index \(index) succeeded to load but it should have failed.")
                case .failure:
                    break
                }
            }
        }
        wait(for: [loadExpectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testLoadPerformance() {
        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { _, _, _ in }
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1050, currency: "USD"),
                                                            confirmHandler: confirmHandler)
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.apiClient = apiClient

        let options = XCTMeasureOptions()
        options.iterationCount = 0
        // ☝️ iterationCount is 0 because this isn't a good automated unit test (it makes live network requests)
        // Set it to another number to manually run if you're making changes to load and want to measure its performance.
        measure(options: options) {
            let e = expectation(description: "")
            PaymentSheetLoader.load(mode: .deferredIntent(intentConfig), configuration: configuration) { result in
                switch result {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                case .success:
                    break
                }
                e.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }
}
