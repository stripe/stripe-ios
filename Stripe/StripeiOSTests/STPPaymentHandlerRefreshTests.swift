//
//  STPPaymentHandlerRefreshTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 4/2/24.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import Stripe3DS2
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentHandlerCashAppTest: XCTestCase, STPAuthenticationContext {
    
    var paymentHandler: STPPaymentHandler!
    var apiClientMock: STPAPIClientMock!
    
    override func setUp() {
        super.setUp()
        
        apiClientMock = STPAPIClientMock()
        paymentHandler = STPPaymentHandler(apiClient: apiClientMock)
    }
    
    func testCashAppRetrievalAndCheckIntent() {
        let currentAction = STPPaymentHandlerPaymentIntentActionParams.makeTestable(apiClient: apiClientMock)
        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction()
        
        XCTAssertTrue(apiClientMock.refreshPaymentIntentCalled)
    }
    
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

class STPAuthenticationContextMock: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

class STPAPIClientMock: STPAPIClient {
    var refreshPaymentIntentCalled = false
    var refreshSetupIntentCalled = false
    
    override func refreshPaymentIntent(withClientSecret secret: String, completion: @escaping STPPaymentIntentCompletionBlock) {
        refreshPaymentIntentCalled = true
    }
    
    override func refreshSetupIntent(withClientSecret secret: String, completion: @escaping STPSetupIntentCompletionBlock) {
        refreshSetupIntentCalled = true
    }
}

extension STPPaymentHandlerPaymentIntentActionParams {
    static func makeTestable(apiClient: STPAPIClient) -> STPPaymentHandlerPaymentIntentActionParams {
        return .init(apiClient: apiClient,
                     authenticationContext: STPAuthenticationContextMock(),
                     threeDSCustomizationSettings: .init(),
                     paymentIntent: STPFixtures.paymentIntent(paymentMethodTypes: ["cashapp"], status: .requiresAction),
                     returnURL: nil) { _, _, _ in
            // no-op
        }
    }
}
