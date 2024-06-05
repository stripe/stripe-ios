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
    public let expiryMonth: String?
    public let expiryYear: String?
    public let name: String?

    init(
        pan: String,
        expiryMonth: String? = nil,
        expiryYear: String? = nil,
        name: String? = nil
    ) {
        self.pan = pan
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.name = name
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
