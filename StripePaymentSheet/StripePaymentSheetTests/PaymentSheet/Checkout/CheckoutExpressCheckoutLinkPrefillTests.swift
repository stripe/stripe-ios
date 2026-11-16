//
//  CheckoutExpressCheckoutLinkPrefillTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 11/13/26.
//

import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

extension CheckoutTests {

    func testLiveExpressCheckoutLinkPrefillsMerchantDefaultPhone() async throws {
        // Given a guest on a live card-only session whose email has no Link account yet
        HTTPStubs.removeAllStubs()
        let defaultPhone = "+12015550123"
        let email = "mobile-payments-sdk-ci+\(UUID().uuidString.lowercased())@stripe.com"
        let keyResponse = try await customerLogicBackendRequest(endpoint: "publishable_key?merchant=US")
        let apiClient = STPAPIClient(publishableKey: try XCTUnwrap(keyResponse["publishable_key"] as? String))

        // Checkout's load-time Link lookup writes the shared Link account, so restore it however the test ends
        let previousLinkAccount = LinkAccountContext.shared.account
        defer {
            LinkAccountContext.shared.account = previousLinkAccount
        }

        let sessionResponse = try await customerLogicBackendRequest(endpoint: "create_checkout_session", parameters: [
            "merchant": "US",
            "stripe_version": STPTestingAPIClient.checkoutMobileElementsAPISettings,
            "request_params": [
                "ui_mode": "mobile_elements",
                "currency": "usd",
                "allowed_payment_method_types": ["card"],
                "customer_email": email,
                "items": [
                    [
                        "type": "one_time_price",
                        "one_time_price": [
                            "items": [
                                [
                                    "price_data": [
                                        "currency": "usd",
                                        "unit_amount": 2000,
                                        "product_data": ["name": "Customer logic repro"],
                                    ],
                                    "quantity": 1,
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ])

        // ...and a merchant that supplies the customer's phone through Checkout's defaults
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: try XCTUnwrap(sessionResponse["client_secret"] as? String),
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.defaults.phone = defaultPhone
        // ...and shows both Payment Element and Express Checkout Element
        configuration.paymentElement = .init()
        configuration.expressCheckoutElement = .init(completion: { _ in })
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // ...where the session carries the server email and Express Checkout Element shows its Link button
        XCTAssertEqual(checkout.session.email?.lowercased(), email, "The session must carry the server-side customer email")
        XCTAssertTrue(
            checkout.session.availableExpressCheckoutPaymentMethods.contains(.link),
            "Express Checkout Element must offer Link; available: \(checkout.session.availableExpressCheckoutPaymentMethods)"
        )
        // ...the load-time Link lookup found that email unregistered, so the Link sheet opens on its signup screen
        XCTAssertEqual(
            LinkAccountContext.shared.account?.email.lowercased(),
            email,
            "Checkout should look up the session email in Link while loading"
        )
        XCTAssertEqual(
            LinkAccountContext.shared.account?.sessionState,
            .requiresSignUp,
            "The fresh email must not have a Link account"
        )
        // ...and Payment Element already hands the merchant's phone to the Link flows it starts
        let paymentElement = checkout.getPaymentElement()
        XCTAssertEqual(
            paymentElement.paymentSheetFlowController.configuration.defaultBillingDetails.phone,
            defaultPhone,
            "Payment Element's sheet configuration should carry the default phone"
        )
        XCTAssertEqual(
            paymentElement.embeddedPaymentElement.configuration.defaultBillingDetails.phone,
            defaultPhone,
            "Payment Element's embedded configuration should carry the default phone"
        )

        // When the customer taps Link in Express Checkout Element, which builds this confirmation flow
        let window = UIWindow()
        window.rootViewController = UIViewController()
        let flow = try checkout.makeExpressCheckoutConfirmationFlow(.link, presentationWindow: window)

        // Then the flow opens the Link wallet...
        guard case .link(let parameters) = flow else {
            return XCTFail("Expected a Link confirmation flow, got \(flow)")
        }
        guard case .wallet = parameters.confirmOption else {
            return XCTFail("Express Checkout Element should open Link as a wallet, got \(parameters.confirmOption)")
        }
        // ...with the session email, which the signup screen prefills alongside the phone
        XCTAssertEqual(
            parameters.configuration.defaultBillingDetails.email?.lowercased(),
            email,
            "Link should receive the session email"
        )

        // ...and with the merchant's phone. Native Link's signup screen prefills its required phone field from
        // this configuration, so a nil phone leaves that field empty for the customer to retype.
        XCTAssertEqual(
            parameters.configuration.defaultBillingDetails.phone,
            defaultPhone,
            "Express Checkout Element's Link configuration dropped the merchant's default phone"
        )
    }
}
