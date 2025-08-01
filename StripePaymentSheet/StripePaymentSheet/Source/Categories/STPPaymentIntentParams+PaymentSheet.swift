//
//  STPPaymentIntentParams+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/6/25.
//

import Foundation
@_spi(STP) import StripePaymentsUI

extension STPPaymentIntentParams {
    var nonnil_paymentMethodOptions: STPConfirmPaymentMethodOptions {
        guard let paymentMethodOptions else {
            let paymentMethodOptions = STPConfirmPaymentMethodOptions()
            self.paymentMethodOptions = paymentMethodOptions
            return paymentMethodOptions
        }
        return paymentMethodOptions
    }
}
