//
//  LinkPaymentDetails.swift
//  StripePayments
//
//  Created by Till Hellmund on 4/21/25.
//

import Foundation

@_spi(STP) public struct LinkPaymentDetails {
    public let expMonth: Int
    public let expYear: Int
    public let last4: String
    public let brand: STPCardBrand

    @_spi(STP) public init(
        expMonth: Int,
        expYear: Int,
        last4: String,
        brand: STPCardBrand
    ) {
        self.expMonth = expMonth
        self.expYear = expYear
        self.last4 = last4
        self.brand = brand
    }
}
