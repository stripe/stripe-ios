//
//  PKAddPaymentPassRequest+Stripe_Error.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 9/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import ObjectiveC
import PassKit

var stpAddPaymentPassRequest: UInt8 = 0

// This is used to store an error on a PKAddPaymentPassRequest
// so that STPFakeAddPaymentPassViewController can inspect it for debugging.
extension PKAddPaymentPassRequest {
    @objc var stp_error: NSError? {
        get {
            return objc_getAssociatedObject(self, &stpAddPaymentPassRequest) as? NSError
        }
        set(stp_error) {
            objc_setAssociatedObject(
                self,
                &stpAddPaymentPassRequest,
                stp_error,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
