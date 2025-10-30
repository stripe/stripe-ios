//
//  STPPaymentIntentParams+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/6/25.
//

import Foundation
@_spi(STP) import StripePaymentsUI

extension STPPaymentIntentConfirmParams {
    var nonnil_paymentMethodOptions: STPConfirmPaymentMethodOptions {
        guard let paymentMethodOptions else {
            let paymentMethodOptions = STPConfirmPaymentMethodOptions()
            self.paymentMethodOptions = paymentMethodOptions
            return paymentMethodOptions
        }
        return paymentMethodOptions
    }
}

extension STPConfirmPaymentMethodOptions {
    @_spi(STP) public func setupFutureUsage(for paymentMethodType: STPPaymentMethodType) -> String? {
        // There are multiple ways to specify SFU for a PM (e.g. paymentMethodOptions.cardOptions.additionalAPIParameters or paymentMethodOptions.additionalAPIParameters) in code, so we convert to the raw JSON to avoid all that.
        let dict = STPFormEncoder.dictionary(forObject: self)
        return dict[jsonDict: Self.rootObjectName()!]?[jsonDict: paymentMethodType.identifier]?["setup_future_usage"] as? String
    }
}
