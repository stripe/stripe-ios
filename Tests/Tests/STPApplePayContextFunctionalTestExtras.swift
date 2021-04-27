//
//  STPApplePayContextFunctionalTestExtras.swift
//  StripeiOS Tests
//
//  Created by David Estes on 3/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@testable import Stripe

@available(iOS 13.0, *)
@objc class STPApplePayContextFunctionalTestAPIClient : STPAPIClient {
    @objc var applePayContext: STPApplePayContext
    @objc var shouldSimulateCancelAfterConfirmBegins: Bool = false
    
    override func confirmPaymentIntent(with paymentIntentParams: STPPaymentIntentParams, completion: @escaping STPPaymentIntentCompletionBlock) {
        super.confirmPaymentIntent(with: paymentIntentParams, completion: completion)
        if shouldSimulateCancelAfterConfirmBegins {
            applePayContext.paymentAuthorizationControllerDidFinish(self.applePayContext.authorizationController!)
        }
    }
    
    override func confirmSetupIntent(with setupIntentParams: STPSetupIntentConfirmParams, completion: @escaping STPSetupIntentCompletionBlock) {
        super.confirmSetupIntent(with: setupIntentParams, completion: completion)
        if shouldSimulateCancelAfterConfirmBegins {
            applePayContext.paymentAuthorizationControllerDidFinish(self.applePayContext.authorizationController!)
        }
    }
}
