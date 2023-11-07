//
//  ScannedCard.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/17/21.
//

import Foundation

/// An struct that contains the PAN of the scanned card during
/// the card image verification flow
public struct ScannedCard: Equatable {
    public let pan: String
    @_spi(STP) public let expiryMonth: String?
    @_spi(STP) public let expiryYear: String?
    @_spi(STP) public let name: String?

    init(
        pan: String,
        expiryMonth: String? = nil,
        expiryYear: String? = nil,
        name: String? = nil
    ) {
        self.pan = pan
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.name = expiryYear
    }
}

extension ScannedCard {
    init(scannedCard: CreditCard) {
        self.init(
            pan: scannedCard.number,
            expiryMonth: scannedCard.expiryMonth,
            expiryYear: scannedCard.expiryYear,
            name: scannedCard.name
        )
    }
}
