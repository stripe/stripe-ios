//
//  PaymentDetailsViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/20/24.
//

import SafariServices
@_spi(PrivateBetaConnect) @_spi(DashboardOnly) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class PaymentDetailsViewControllerTests: XCTestCase {
    @MainActor
    func testDelegate() async throws {
        STPAPIClient.shared.publishableKey = "pk_test"
        let componentManager = EmbeddedComponentManager(fetchClientSecret: {
            return nil
        })
        let vc = componentManager.createPaymentDetailsViewController()

        let expectationDidFail = XCTestExpectation(description: "loadDidFail called")

        let paymentDetailsDelegate = PaymentDetailsViewControllerDelegatePassThrough { _, error in
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        vc.delegate = paymentDetailsDelegate

        try await vc.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")

        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    func testSetPayment() throws {
        STPAPIClient.shared.publishableKey = "pk_test"
        let componentManager = EmbeddedComponentManager(fetchClientSecret: {
            return nil
        })
        let vc = componentManager.createPaymentDetailsViewController()
        let expectation = try vc.webVC.webView.expectationForMessageReceived(sender: CallSetterWithSerializableValueSender(payload: .init(
            setter: "setPayment",
            value: "pi_123"
        )))

        vc.setPayment(id: "pi_123")
        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}

private class PaymentDetailsViewControllerDelegatePassThrough: PaymentDetailsViewControllerDelegate {

    var didFailLoad: ((_ paymentDetails: PaymentDetailsViewController, _ error: any Error) -> Void)?

    init(didFailLoad: ((PaymentDetailsViewController, any Error) -> Void)? = nil) {
        self.didFailLoad = didFailLoad
    }

    func paymentDetails(_ paymentDetails: PaymentDetailsViewController, didFailLoadWithError error: any Error) {
        didFailLoad?(paymentDetails, error)
    }
}
