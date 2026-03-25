//
//  PaymentMethodIncentive.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 11/19/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct PaymentMethodIncentive: Equatable {

    let identifier: String
    let displayText: String

    func takeIfAppliesTo(_ paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodIncentive? {
        return identifier == paymentMethodType.incentiveIdentifier ? self : nil
    }
}

extension PaymentMethodIncentive {

    init?(from incentive: LinkConsumerIncentive) {
        guard let displayText = incentive.incentiveDisplayText else {
            return nil
        }
        
        self.identifier = incentive.incentiveParams.paymentMethod
        self.displayText = displayText
    }
}
