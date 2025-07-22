//
//  PaymentsViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Torrance Yan on 7/22/25.
//

import SafariServices
@_spi(DashboardOnly) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class PaymentsViewControllerTests: XCTestCase {
    let componentManager = EmbeddedComponentManager(fetchClientSecret: {
        return nil
    })

    override func setUp() {
        super.setUp()
        STPAPIClient.shared.publishableKey = "pk_test"
    }

    @MainActor
    func testDelegate() async throws {
        let delegate = PaymentsViewControllerDelegatePassThrough()
        let vc = componentManager.createPaymentsViewController()
        vc.delegate = delegate

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        delegate.paymentsDidFailLoadWithError = { paymentsVC, error in
            XCTAssertEqual(vc, paymentsVC)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        try await vc.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    private class PaymentsViewControllerDelegatePassThrough: PaymentsViewControllerDelegate {

        var paymentsDidFailLoadWithError: ((_ payments: PaymentsViewController, _ error: Error) -> Void)?

        func payments(_ payments: PaymentsViewController,
                      didFailLoadWithError error: Error)
        {
            paymentsDidFailLoadWithError?(payments, error)
        }
    }

}
