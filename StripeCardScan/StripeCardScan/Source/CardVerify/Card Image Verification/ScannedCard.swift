//
//  ScannedCard.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/17/21.
//

import Foundation

/**
 An struct that contains the PAN of the scanned card during
 the card image verification flow
 */
public struct ScannedCard: Equatable {
    public let pan: String
}
