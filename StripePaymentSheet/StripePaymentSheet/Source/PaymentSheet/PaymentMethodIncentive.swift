//
//  PaymentMethodIncentive.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 11/13/24.
//

import Foundation
@_spi(STP) import StripePayments

struct PaymentMethodIncentive {
    
    let identifier: String
    let displayText: String
    
    init(
        identifier: String,
        text: String
    ) {
        self.identifier = identifier
        self.displayText = text
    }
    
    func takeIfAppliesTo(_ paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodIncentive? {
        switch paymentMethodType {
        case .stripe, .external:
            return nil
        case .instantDebits, .linkCardBrand:
            return identifier == "link_instant_debits" ? self : nil
        }
    }
}

extension PaymentMethodIncentive {
    
    init?(from linkConsumerIncentive: LinkConsumerIncentive) {
        self.identifier = linkConsumerIncentive.incentiveParams.paymentMethod
        
        let incentiveParams = linkConsumerIncentive.incentiveParams
        
        if let amountFlat = incentiveParams.amountFlat, let currency = incentiveParams.currency {
            self.displayText = String.localizedAmountDisplayString(for: amountFlat, currency: currency, compact: true)
        } else if let amountPercent = incentiveParams.amountPercent {
            self.displayText = "\(Int((amountPercent * 100).rounded()))%"
        } else {
            return nil
        }
    }
}
