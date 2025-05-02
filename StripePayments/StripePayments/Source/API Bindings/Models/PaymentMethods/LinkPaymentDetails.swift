//
//  LinkPaymentDetails.swift
//  StripePayments
//
//  Created by Till Hellmund on 4/21/25.
//

import Foundation

@_spi(STP) public struct LinkPaymentDetails {

    public var last4: String
    public var brand: STPCardBrand

    @_spi(STP) public init(last4: String, brand: STPCardBrand) {
        self.last4 = last4
        self.brand = brand
    }
}
