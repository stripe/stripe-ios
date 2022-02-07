//
//  STPApplePayContextFunctionalTestExtras.swift
//  StripeiOS Tests
//
//  Created by David Estes on 3/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@testable import Stripe
@testable import StripeCore
@testable import StripeApplePay
import OHHTTPStubs

@available(iOS 13.0, *)
class STPApplePayContextFunctionalTestAPIClient: _stpobjc_STPAPIClient {
    @objc var applePayContext: _stpobjc_APContext
    @objc var shouldSimulateCancelAfterConfirmBegins: Bool = false
    
    @objc func setupStubs() {
        stub { urlRequest in
            // Hook SetupIntent or PaymentIntent confirmation
            if let urlString = urlRequest.url?.absoluteString,
               urlString.contains("_intents/"),
               urlString.hasSuffix("/confirm") {
                if self.shouldSimulateCancelAfterConfirmBegins {
                    self.applePayContext._applePayContext.paymentAuthorizationControllerDidFinish(self.applePayContext._applePayContext.authorizationController!)
                }
            }
            // Let everything pass through to the underlying API
            return false
        } response: { urlRequest in
            // This doesn't matter, we're not sending responses for anything.
            return HTTPStubsResponse()
        }
    }
}
