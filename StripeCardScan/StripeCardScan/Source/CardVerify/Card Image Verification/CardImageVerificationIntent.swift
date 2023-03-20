//
//  CardImageVerificationIntent.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/22/21.
//

import Foundation

/// An internal type representing a Card Image Verification Intent
struct CardImageVerificationIntent {
    /// The card verification intent id
    let id: String
    /// The card verification intent client secret
    let clientSecret: String
}
