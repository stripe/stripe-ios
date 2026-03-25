//
//  Intent+SellerDetails.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 8/13/25.
//

import Foundation

extension Intent {
    var sellerDetails: PaymentSheet.IntentConfiguration.SellerDetails? {
        guard case let .deferredIntent(intentConfig) = self else {
            return nil
        }
        return intentConfig.sellerDetails
    }
}
