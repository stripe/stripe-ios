//
//  LinkPaymentDetails.swift
//  StripePayments
//
//  Created by Till Hellmund on 4/21/25.
//

import Foundation

@_spi(STP) public struct LinkPaymentDetails {
    public let displayName: String?
    public let expMonth: Int
    public let expYear: Int
    public let last4: String
    public let brand: STPCardBrand

    public var label: String {
        displayName ?? "•••• \(last4)"
    }

    public var sublabel: String? {
        displayName != nil ? "•••• \(last4)" : nil
    }

    @_spi(STP) public init(
        displayName: String?,
        expMonth: Int,
        expYear: Int,
        last4: String,
        brand: STPCardBrand
    ) {
        self.displayName = displayName
        self.expMonth = expMonth
        self.expYear = expYear
        self.last4 = last4
        self.brand = brand
    }
}
