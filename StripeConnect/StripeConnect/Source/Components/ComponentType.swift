//
//  ComponentType.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/21/24.
//

import Foundation

/// The name of the embedded component tag in JS ([docs](https://docs.stripe.com/connect/supported-embedded-components))
enum ComponentType: Encodable {
    /// Displays the balance summary, the payout schedule, and a list of payouts for the connected account
    case payouts
    /// The onboarding flow for the account.
    case onboarding(AccountOnboardingViewController.Props)
    /// Show details of a given payment and allow users to manage disputes and perform refunds.
    case paymentDetails

    var name: String {
        switch self {
        case .payouts:
            return "payouts"
        case .onboarding:
            return "account-onboarding"
        case .paymentDetails:
            return "payment-details"
        }
    }

    func encode(to encoder: any Encoder) throws {
        switch self {
        case .onboarding(let initParams):
            try initParams.encode(to: encoder)
        case .payouts,
             .paymentDetails:
            try VoidPayload().encode(to: encoder)
        }
    }
}
