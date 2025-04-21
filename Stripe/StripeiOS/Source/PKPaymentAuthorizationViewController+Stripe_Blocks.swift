//
//  PKPaymentAuthorizationViewController+Stripe_Blocks.swift
//  StripeiOS
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import ObjectiveC
import PassKit

typealias STPApplePayPaymentMethodHandlerBlock = (STPPaymentMethod, @escaping STPPaymentStatusBlock)
    -> Void
typealias STPPaymentCompletionBlock = (STPPaymentStatus, Error?) -> Void
typealias STPPaymentAuthorizationBlock = (PKPayment) -> Void

typealias STPApplePayShippingMethodCompletionBlock = (
    PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]?
) -> Void
typealias STPApplePayShippingAddressCompletionBlock = (
    PKPaymentAuthorizationStatus, [PKShippingMethod]?, [PKPaymentSummaryItem]?
) -> Void

typealias STPPaymentAuthorizationStatusCallback = (PKPaymentAuthorizationStatus) -> Void
