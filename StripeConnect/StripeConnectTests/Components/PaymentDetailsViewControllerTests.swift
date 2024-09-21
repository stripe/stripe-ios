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

    func testSetPayment() throws {
        STPAPIClient.shared.publishableKey = "pk_test"
        let componentManager = EmbeddedComponentManager(fetchClientSecret: {
            return nil
        })
        let vc = componentManager.createPaymentDetailsViewController()
        let expectation = try vc.webView.expectationForMessageReceived(sender: CallSetterWithSerializableValueSender(payload: .init(
            setter: "setPayment",
            value: "pi_123"
        )))

        vc.setPayment(id: "pi_123")
        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    func testLoadDidFail() {
        STPAPIClient.shared.publishableKey = "pk_test"
        let componentManager = EmbeddedComponentManager(fetchClientSecret: {
            return nil
        })
        let vc = componentManager.createPaymentDetailsViewController()

        let expectation = XCTestExpectation(description: "loadDidFail called")

        let paymentDetailsDelegate = PaymentDetailsViewControllerDelegatePassThrough(loadDidFail: { _, error in
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectation.fulfill()
        })
        vc.delegate = paymentDetailsDelegate

        vc.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")

        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }

    func testDidClose() {
        STPAPIClient.shared.publishableKey = "pk_test"
        let componentManager = EmbeddedComponentManager(fetchClientSecret: {
            return nil
        })
        let vc = componentManager.createPaymentDetailsViewController()

        let expectation = XCTestExpectation(description: "didClose called")

        let paymentDetailsDelegate = PaymentDetailsViewControllerDelegatePassThrough(didClose: { _ in
            expectation.fulfill()
        })
        vc.delegate = paymentDetailsDelegate
        vc.webView.evaluateMessage(name: "onSetterFunctionCalled", json: "{ \"setter\": \"setOnClose\" }")
        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}

private class PaymentDetailsViewControllerDelegatePassThrough: PaymentDetailsViewControllerDelegate {

    var loadDidFail: ((_ paymentDetails: PaymentDetailsViewController, _ error: any Error) -> Void)?
    var didClose: ((PaymentDetailsViewController) -> Void)?

    init(loadDidFail: ((PaymentDetailsViewController, any Error) -> Void)? = nil,
         didClose: ((PaymentDetailsViewController) -> Void)? = nil) {
        self.loadDidFail = loadDidFail
        self.didClose = didClose
    }

    func paymentDetailsLoadDidFail(_ paymentDetails: PaymentDetailsViewController, withError error: any Error) {
        loadDidFail?(paymentDetails, error)
    }

    func paymentDetailsDidClose(_ paymentDetails: PaymentDetailsViewController) {
        didClose?(paymentDetails)
    }
}
