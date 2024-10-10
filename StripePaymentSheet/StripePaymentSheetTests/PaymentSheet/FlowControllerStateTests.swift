//
//  FlowControllerStateTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class FlowControllerStateTests: XCTestCase {

    func testAddPaymentMethodViewControllerDelegate() {
        let exp = expectation(description: "No delegate methods should be called during init but before viewDidLoad")
        exp.isInverted = true
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        let apmvcDelegate = StubAPMVCDelegate(expectation: exp)
        _ = AddPaymentMethodViewController(
            intent: intent,
            elementsSession: .emptyElementsSession,
            configuration: config,
            paymentMethodTypes: [.stripe(.card)],
            formCache: .init(),
            analyticsHelper: ._testValue(),
            delegate: apmvcDelegate
        )
        waitForExpectations(timeout: 0.1)
    }
}

class StubAPMVCDelegate: AddPaymentMethodViewControllerDelegate {
    let expectation: XCTestExpectation
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func didUpdate(_ viewController: StripePaymentSheet.AddPaymentMethodViewController) {
        expectation.fulfill()
    }

    func updateErrorLabel(for: Error?) {
        expectation.fulfill()
    }

}
