//
//  ComponentType.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/21/24.
//

import Foundation

enum ComponentType: String, Encodable {
    /// Displays the balance summary, the payout schedule, and a list of payouts for the connected account
    case payouts
    case onboarding
    case paymentDetails = "payment-details"
}
