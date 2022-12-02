//
//  STPPaymentIntentParams+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension STPPaymentIntentParams {
    /// Provide an STPPaymentResult from STPPaymentContext, and this will populate
    /// the proper field (either paymentMethodId or paymentMethodParams) for your PaymentMethod.
    @objc
    public func configure(with paymentResult: STPPaymentResult) {
        if let paymentMethod = paymentResult.paymentMethod {
            paymentMethodId = paymentMethod.stripeId
        } else if let params = paymentResult.paymentMethodParams {
            paymentMethodParams = params
        }
    }
}
