//
//  PayoutsViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/21/24.
//

import SafariServices
@_spi(PrivateBetaConnect) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class PayoutsViewControllerTests: XCTestCase {

    private class PayoutViewControllerDelegatePassThrough: PayoutsViewControllerDelegate {

        internal init(payoutDidFail: ((PayoutsViewController, any Error) -> Void)? = nil) {
            self.payoutDidFail = payoutDidFail
        }

        var payoutDidFail: ((_ payouts: PayoutsViewController, _ error: any Error) -> Void)?

        func payoutsLoadDidFail(_ payouts: PayoutsViewController, withError error: any Error) {
            payoutDidFail?(payouts, error)
        }
    }

    func testPayoutsViewControllerDelegate() {
        STPAPIClient.shared.publishableKey = "pk_test"
        let componentManager = EmbeddedComponentManager(fetchClientSecret: {
            return nil
        })
        let vc = componentManager.createPayoutsViewController()

        let expectation = XCTestExpectation(description: "Delegate called")
        let payoutsDelegate = PayoutViewControllerDelegatePassThrough { _, error in
            expectation.fulfill()
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
        }
        vc.delegate = payoutsDelegate

        vc.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
