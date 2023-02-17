//
//  PaymentSheet+APITest.swift
//  StripeiOS Tests
//
//  Created by Jaime Park on 6/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet

class PaymentSheetAPITest: XCTestCase {

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
        config.shippingDetails = {
            return .init(
                address: .init(
                    country: "US",
                    line1: "Line 1"
                ),
                name: "Jane Doe",
                phone: "5551234567"
            )
        }
        return config
    }()

    override class func setUp() {
        super.setUp()
        // `PaymentSheet.load()` uses the `LinkAccountService` to lookup the Link user account.
        // Override the default cookie store since Keychain is not available in this test case.
        LinkAccountService.defaultCookieStore = LinkInMemoryCookieStore()
    }

    func fetchPaymentIntent(
        types: [String],
        completion: @escaping (Result<(String), Error>) -> Void
    ) {
        STPTestingAPIClient
            .shared()
            .createPaymentIntent(
                withParams: [
                    "amount": 1050,
                    "currency": "eur",
                    "payment_method_types": types,
                ]
            ) { clientSecret, error in
                guard let clientSecret = clientSecret,
                    error == nil
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
            }
    }

    func fetchSetupIntent(types: [String], completion: @escaping (Result<(String), Error>) -> Void)
    {
        STPTestingAPIClient
            .shared()
            .createSetupIntent(
                withParams: [
                    "payment_method_types": types
                ]
            ) { clientSecret, error in
                guard let clientSecret = clientSecret,
                    error == nil
                else {
                    completion(.failure(error!))
                    return
                }

                completion(.success(clientSecret))
            }
    }

    func testPaymentSheetLoadAndConfirmWithPaymentIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Payment Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected = [.card, .iDEAL, .bancontact, .sofort]
            .filter { PaymentSheet.supportedPaymentMethods.contains($0) }

        // 0. Create a PI on our test backend
        fetchPaymentIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                // 1. Load the PI
                PaymentSheet.load(
                    mode: .paymentIntentClientSecret(clientSecret),
                    configuration: self.configuration
                ) { result in
                    switch result {
                    case .success(let paymentIntent, let paymentMethods, _):
                        XCTAssertEqual(
                            Set(paymentIntent.recommendedPaymentMethodTypes),
                            Set(expected)
                        )
                        XCTAssertEqual(paymentMethods, [])
                        // 2. Confirm the intent with a new card
                        let cardParams = STPPaymentMethodCardParams()
                        cardParams.number = "4242424242424242"
                        cardParams.cvc = "123"
                        cardParams.expYear = 32
                        cardParams.expMonth = 12
                        let newCardPaymentOption: PaymentSheet.PaymentOption = .new(
                            confirmParams: .init(
                                params: .init(
                                    card: cardParams,
                                    billingDetails: .init(),
                                    metadata: nil
                                ),
                                type: .card
                            )
                        )

                        PaymentSheet.confirm(
                            configuration: self.configuration,
                            authenticationContext: self,
                            intent: paymentIntent,
                            paymentOption: newCardPaymentOption,
                            paymentHandler: self.paymentHandler
                        ) { result in
                            switch result {
                            case .completed:
                                // 3. Fetch the PI
                                self.apiClient.retrievePaymentIntent(withClientSecret: clientSecret)
                                { paymentIntent, _ in
                                    // Make sure the PI is succeeded and contains shipping
                                    XCTAssertNotNil(paymentIntent?.shipping)
                                    XCTAssertEqual(
                                        paymentIntent?.shipping?.name,
                                        self.configuration.shippingDetails()?.name
                                    )
                                    XCTAssertEqual(
                                        paymentIntent?.shipping?.phone,
                                        self.configuration.shippingDetails()?.phone
                                    )
                                    XCTAssertEqual(
                                        paymentIntent?.shipping?.address?.line1,
                                        self.configuration.shippingDetails()?.address.line1
                                    )
                                    XCTAssertEqual(paymentIntent?.status, .succeeded)
                                }
                            case .canceled:
                                XCTFail("Confirm canceled")
                            case .failed(let error):
                                XCTFail("Failed to confirm: \(error)")
                            }
                            expectation.fulfill()
                        }
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

    func testPaymentSheetLoadWithSetupIntent() {
        let expectation = XCTestExpectation(description: "Retrieve Setup Intent With Preferences")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card, .iDEAL, .bancontact, .sofort]
        fetchSetupIntent(types: types) { result in
            switch result {
            case .success(let clientSecret):
                PaymentSheet.load(
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

    func testPaymentSheetLoadWithDeferredIntent() {
        let expectation = XCTestExpectation(description: "Load PaymentSheet")
        let types = ["ideal", "card", "bancontact", "sofort"]
        let expected: [STPPaymentMethodType] = [.card, .iDEAL, .bancontact, .sofort]

        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000,
                                                                           currency: "USD",
                                                                           setupFutureUsage: .onSession),
                                                            captureMethod: .automatic,
                                                            paymentMethodTypes: types)

        PaymentSheet.load(
            mode: .deferredIntent(intentConfig),
            configuration: self.configuration
        ) { result in
            switch result {
            case .success(let elementsSession, let paymentMethods, _):
                XCTAssertEqual(
                    Set(elementsSession.recommendedPaymentMethodTypes),
                    Set(expected)
                )
                XCTAssertEqual(paymentMethods, [])
                expectation.fulfill()
            case .failure(let error):
                print(error)
            }
        }

        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadAndConfirmWithPaymentIntentAttachedPaymentMethod() {
        let expectation = XCTestExpectation(
            description: "Load PaymentIntent with an attached payment method"
        )
        // 0. Create a PI on our test backend with an already attached pm
        STPTestingAPIClient.shared().createPaymentIntent(withParams: [
            "amount": 1050,
            "payment_method": "pm_card_visa",
        ]) { clientSecret, error in
            guard let clientSecret = clientSecret, error == nil else {
                XCTFail()
                return
            }

            // 1. Load the PI
            PaymentSheet.load(
                mode: .paymentIntentClientSecret(clientSecret),
                configuration: self.configuration
            ) { result in
                guard case .success(let paymentIntent, _, _) = result else {
                    XCTFail()
                    return
                }
                // 2. Confirm with saved card
                PaymentSheet.confirm(
                    configuration: self.configuration,
                    authenticationContext: self,
                    intent: paymentIntent,
                    paymentOption: .saved(paymentMethod: .init(stripeId: "pm_card_visa")),
                    paymentHandler: self.paymentHandler
                ) { result in
                    switch result {
                    case .completed:
                        // 3. Fetch the PI
                        self.apiClient.retrievePaymentIntent(withClientSecret: clientSecret) {
                            paymentIntent,
                            _ in
                            // Make sure the PI is succeeded and contains shipping
                            XCTAssertNotNil(paymentIntent?.shipping)
                            XCTAssertEqual(
                                paymentIntent?.shipping?.name,
                                self.configuration.shippingDetails()?.name
                            )
                            XCTAssertEqual(
                                paymentIntent?.shipping?.phone,
                                self.configuration.shippingDetails()?.phone
                            )
                            XCTAssertEqual(
                                paymentIntent?.shipping?.address?.line1,
                                self.configuration.shippingDetails()?.address.line1
                            )
                            XCTAssertEqual(paymentIntent?.status, .succeeded)
                            expectation.fulfill()
                        }
                    case .canceled:
                        XCTFail("Confirm canceled")
                    case .failed(let error):
                        XCTFail("Failed to confirm: \(error)")
                    }
                }
            }
        }
        wait(for: [expectation], timeout: STPTestingNetworkRequestTimeout)
    }

    func testPaymentSheetLoadWithSetupIntentAttachedPaymentMethod() {
        let expectation = XCTestExpectation(
            description: "Load SetupIntent with an attached payment method"
        )
        STPTestingAPIClient.shared().createSetupIntent(withParams: [
            "payment_method": "pm_card_visa"
        ]) { clientSecret, error in
            guard let clientSecret = clientSecret, error == nil else {
                XCTFail()
                expectation.fulfill()
                return
            }

            PaymentSheet.load(
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

    func testMakeShippingParamsReturnsNilIfPaymentIntentHasDifferentShipping() {
        // Given a PI with shipping...
        let pi = STPFixtures.paymentIntent()
        guard let shipping = pi.shipping else {
            XCTFail("PI should contain shipping")
            return
        }
        // ...and a configuration with *a different* shipping
        var config = configuration
        // ...PaymentSheet should set shipping params on /confirm
        XCTAssertNotNil(PaymentSheet.makeShippingParams(for: pi, configuration: config))

        // However, if the PI and config have the same shipping...
        config.shippingDetails = {
            return .init(
                address: AddressViewController.AddressDetails.Address(
                    city: shipping.address?.city,
                    country: shipping.address?.country ?? "pi.shipping is missing country",
                    line1: shipping.address?.line1 ?? "pi.shipping is missing line1",
                    line2: shipping.address?.line2,
                    postalCode: shipping.address?.postalCode,
                    state: shipping.address?.state
                ),
                name: pi.shipping?.name,
                phone: pi.shipping?.phone
            )
        }
        // ...PaymentSheet should not set shipping params on /confirm
        XCTAssertNil(PaymentSheet.makeShippingParams(for: pi, configuration: config))
    }

    /// Setting SFU to `true` when a customer is set should set the parameter to `off_session`.
    func testPaymentIntentParamsWithSFUTrueAndCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            true,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: .init(id: "", ephemeralKeySecret: "")
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        guard
            let paymentMethodOptions = params["payment_method_options"] as? [String: Any],
            let card = paymentMethodOptions["card"] as? [String: Any],
            let setupFutureUsage = card["setup_future_usage"] as? String
        else {
            XCTFail("Incorrect params")
            return
        }

        XCTAssertEqual(setupFutureUsage, "off_session")
    }

    /// Setting SFU to `false` when a customer is set should set the parameter to an empty string.
    func testPaymentIntentParamsWithSFUFalseAndCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            false,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: .init(id: "", ephemeralKeySecret: "")
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        guard
            let paymentMethodOptions = params["payment_method_options"] as? [String: Any],
            let card = paymentMethodOptions["card"] as? [String: Any],
            let setupFutureUsage = card["setup_future_usage"] as? String
        else {
            XCTFail("Incorrect params")
            return
        }

        XCTAssertEqual(setupFutureUsage, "")
    }

    /// Setting SFU to `true` when no customer is set shouldn't set the parameter.
    func testPaymentIntentParamsWithSFUTrueAndNoCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            false,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: nil
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        XCTAssertEqual((params["payment_method_options"] as! [String: Any]).count, 0)
    }

    /// Setting SFU to `false` when no customer is set shouldn't set the parameter.
    func testPaymentIntentParamsWithSFUFalseAndNoCustomer() {
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: "")
        paymentIntentParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        paymentIntentParams.paymentMethodOptions?.setSetupFutureUsageIfNecessary(
            false,
            paymentMethodType: PaymentSheet.PaymentMethodType.card,
            customer: nil
        )

        let params = STPFormEncoder.dictionary(forObject: paymentIntentParams)
        XCTAssertEqual((params["payment_method_options"] as! [String: Any]).count, 0)
    }
}

extension PaymentSheetAPITest: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
