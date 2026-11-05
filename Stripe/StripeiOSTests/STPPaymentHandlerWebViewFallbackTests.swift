//
//  STPPaymentHandlerWebViewFallbackTests.swift
//  StripeiOSTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import SafariServices
@_spi(InternalOnlyAPI) @testable import StripeCore
import StripeCoreTestUtils
@_spi(InternalOnlyAPI) @testable import StripePayments
@_spi(InternalOnlyAPI) @testable import StripePaymentsTestUtils
import UIKit
import XCTest

/// Simulates the customer closing the web view as soon as it's presented.
private final class DismissingPresentingViewController: UIViewController {
    weak var paymentHandler: STPPaymentHandler?
    private(set) var presentedWebView = false

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        #if !os(visionOS)
        if let safariViewController = viewControllerToPresent as? SFSafariViewController {
            presentedWebView = true
            paymentHandler?.safariViewControllerDidFinish(safariViewController)
        }
        #endif
    }
}

/// Next actions that redirect to a URL open a web view when no installed app can open the URL.
final class STPPaymentHandlerWebViewFallbackTests: APIStubbedTestCase, STPAuthenticationContext {
    private let presentingViewController = DismissingPresentingViewController()

    func authenticationPresentingViewController() -> UIViewController {
        return presentingViewController
    }

    func testRedirectOpensWebViewWhenNoAppCanOpenTheURL() {
        // Given a PaymentIntent that requires a redirect, both when confirmed and when retrieved afterwards
        var paymentIntentJSON = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)!
        paymentIntentJSON["payment_method"] = STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)
        let paymentIntentData = try! JSONSerialization.data(withJSONObject: paymentIntentJSON)
        stub { urlRequest in
            urlRequest.url?.path.contains("/v1/payment_intents/") ?? false
        } response: { _ in
            HTTPStubsResponse(data: paymentIntentData, statusCode: 200, headers: nil)
        }
        let paymentHandler = STPPaymentHandler(apiClient: stubbedAPIClient())
        presentingViewController.paymentHandler = paymentHandler
        // ...and no app installed that can open the redirect URL
        var openedURLs: [URL] = []
        paymentHandler._openURL = { url, _, completion in
            openedURLs.append(url)
            completion(false)
        }

        let confirmParams = STPPaymentIntentConfirmParams(clientSecret: "pi_123_secret_456")
        confirmParams.paymentMethodOptions = STPConfirmPaymentMethodOptions()
        confirmParams.paymentMethodOptions?.alipayOptions = STPConfirmAlipayOptions()
        confirmParams.paymentMethodParams = STPPaymentMethodParams(
            alipay: STPPaymentMethodAlipayParams(),
            billingDetails: nil,
            metadata: nil
        )
        confirmParams.returnURL = "foo://bar"

        // When the PaymentIntent is confirmed
        let e = expectation(description: "")
        paymentHandler.confirmPayment(confirmParams, with: self) { status, _, _ in
            // Then the redirect URL is opened in a web view...
            XCTAssertEqual(openedURLs.count, 1)
            XCTAssertTrue(self.presentingViewController.presentedWebView)
            // ...and since the customer closed it without authenticating, the payment is canceled
            XCTAssertEqual(status, .canceled)
            e.fulfill()
        }
        waitForExpectations(timeout: 4)
    }
}

/// Exercises next actions that present a web view against the live test backend.
final class STPPaymentHandlerOXXOFunctionalTest: XCTestCase, STPAuthenticationContext {
    private let presentingViewController = DismissingPresentingViewController()

    func authenticationPresentingViewController() -> UIViewController {
        return presentingViewController
    }

    func test_oxxo_payment_intent_server_side_confirmation() {
        // OXXO is interesting b/c the PI status after handling next actions is requires_action, not succeeded.
        let apiClient = STPAPIClient(publishableKey: STPTestingMEXPublishableKey)
        let paymentHandler = STPPaymentHandler(apiClient: apiClient)
        presentingViewController.paymentHandler = paymentHandler
        // No app can open the voucher URL, so it opens in a web view
        paymentHandler._openURL = { _, _, completion in completion(false) }

        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Test Customer"
        billingDetails.email = "test@example.com"
        let params = STPPaymentMethodParams(oxxo: STPPaymentMethodOXXOParams(), billingDetails: billingDetails, metadata: nil)

        let e = expectation(description: "")
        apiClient.createPaymentMethod(with: params) { paymentMethod, error in
            XCTAssertNil(error)
            guard let paymentMethod else {
                XCTFail("Failed to create a PaymentMethod")
                return
            }
            STPTestingAPIClient.shared.createPaymentIntent(
                withParams: [
                    "confirm": "true",
                    "payment_method_types": ["oxxo"],
                    "currency": "mxn",
                    "amount": 1099,
                    "payment_method": paymentMethod.stripeId,
                    "return_url": "foo://z",
                ],
                account: "mex"
            ) { clientSecret, error2 in
                XCTAssertNil(error2)
                guard let clientSecret else {
                    XCTFail("Failed to create a PaymentIntent")
                    return
                }
                paymentHandler.handleNextAction(forPayment: clientSecret, with: self, returnURL: "foo://z") { status, paymentIntent, error3 in
                    XCTAssertNil(error3)
                    XCTAssertEqual(paymentIntent?.status, .requiresAction)
                    XCTAssertEqual(status, .succeeded)
                    e.fulfill()
                }
            }
        }
        waitForExpectations(timeout: STPTestingNetworkRequestTimeout)
    }
}
