//
//  LinkMode.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-24.
//

import Foundation

@_spi(InternalOnlyAPI) public enum LinkMode: String {
    case linkPaymentMethod = "LINK_PAYMENT_METHOD"
    case passthrough = "PASSTHROUGH"
    case linkCardBrand = "LINK_CARD_BRAND"

    @_spi(InternalOnlyAPI) public var isPantherPayment: Bool {
        self == .linkCardBrand
    }

    @_spi(InternalOnlyAPI) public var expectedPaymentMethodType: String {
        isPantherPayment ? "card" : "bank_account"
    }
}
