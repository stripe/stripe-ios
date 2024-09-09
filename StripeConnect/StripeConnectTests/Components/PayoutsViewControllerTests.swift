//
//  PayoutsViewControllerTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 8/21/24.
//

@_spi(STP) import StripeCore
@_spi(PrivateBetaConnect) @testable import StripeConnect
import XCTest
import WebKit
import SafariServices

class PayoutsViewControllerTests: XCTestCase {
    
    private class PayoutViewControllerDelegatePassThrough: PayoutsViewControllerDelegate {
        
        internal init(payoutDidFail: ((PayoutsViewController, any Error) -> Void)? = nil) {
            self.payoutDidFail = payoutDidFail
        }
        
        var payoutDidFail: ((_ payouts: PayoutsViewController,  _ error: any Error) -> Void)? = nil
       
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
        let payoutsDelegate = PayoutViewControllerDelegatePassThrough()
        vc.delegate = payoutsDelegate
        
        let expectation = XCTestExpectation(description: "Delegate called")
        
        payoutsDelegate.payoutDidFail = { payoutVC, error in
            expectation.fulfill()
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
        }
        
        vc.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")
        
        wait(for: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
