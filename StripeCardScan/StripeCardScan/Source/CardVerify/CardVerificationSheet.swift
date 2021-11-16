//
//  CardVerificationSheet.swift
//  StripeCardScan
//
//  Created by Sam King on 11/12/21.
//

import Foundation

@objc public class CardVerificationSheet: NSObject {
    /**
     Class for running Stripe's Card Verification process
     - Parameters:
       - publishableKey: The user's Stripe publishable key
       - id: The card image verification id received by creating a card image verification intent through the merchant backend
       - clientSecret: The card image verification secret received by creating a card image verification intent through the merchant backend
     */
    @objc public init(publishableKey: String,
                      id: String,
                      clientSecret: String) {
        // Just a stub for now
    }
}
