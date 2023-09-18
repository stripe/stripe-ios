//
//  CardBrandChoiceAvailability.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/5/23.
//

import Foundation

// TODO(porter) Remove this for card brand choice GA
class CardBrandChoiceAvailability {
    // Only for development/testing purposes
    static let shared = CardBrandChoiceAvailability()
    var isCardBrandChoiceAvailable = false
    var test = ""
}
