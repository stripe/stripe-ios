//
//  ComponentType.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/21/24.
//

import Foundation

/// The name of the embedded component tag in JS ([docs](https://docs.stripe.com/connect/supported-embedded-components))
enum ComponentType: String, Encodable {
    case accountManagement = "account-management"
    /// Displays the balance summary, the payout schedule, and a list of payouts for the connected account
    case payouts
    /// The onboarding flow for the account.
    case onboarding = "account-onboarding"
    /// Show details of a given payment and allow users to manage disputes and perform refunds.
    case paymentDetails = "payment-details"
    case notificationBanner = "notification-banner"
}
