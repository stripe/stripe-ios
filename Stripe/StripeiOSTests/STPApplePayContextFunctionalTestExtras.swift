//
//  STPApplePayContextFunctionalTestExtras.swift
//  StripeiOS Tests
//
//  Created by David Estes on 3/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeApplePay
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

class STPApplePayContextFunctionalTestAPIClient: STPAPIClient {
    @objc var applePayContext: STPApplePayContext?
    @objc var shouldSimulateCancelAfterConfirmBegins: Bool = false

    @objc func setupStubs() {
        stub { urlRequest in
            // Hook SetupIntent or PaymentIntent confirmation
            if let urlString = urlRequest.url?.absoluteString,
                urlString.contains("_intents/"),
                urlString.hasSuffix("/confirm")
            {
                if self.shouldSimulateCancelAfterConfirmBegins {
                    self.applePayContext!.paymentAuthorizationControllerDidFinish(
                        self.applePayContext!.authorizationController
                    )
                }
            }
            // Let everything pass through to the underlying API
            return false
        } response: { _ in
            // This doesn't matter, we're not sending responses for anything.
            return HTTPStubsResponse()
        }
    }
}
