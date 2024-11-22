//
//  LinkMode.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-24.
//

import Foundation

@_spi(STP) public enum LinkMode: String {
    case linkPaymentMethod = "LINK_PAYMENT_METHOD"
    case passthrough = "PASSTHROUGH"
    case linkCardBrand = "LINK_CARD_BRAND"

    @_spi(STP) public var isPantherPayment: Bool {
        self == .linkCardBrand
    }

    @_spi(STP) public var expectedPaymentMethodType: String {
        isPantherPayment ? "card" : "bank_account"
    }
}
