//
//  LinkedAccount.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation

public struct LinkedAccount {
    let id: String
    let accountHolder: AccountHolder
    let category: String
    let created: Int
    let displayName: String
    let institutionName: String
    let last4: String
    let livemode: Bool
    let status: String
    let subcategory: String
    let supportedPaymentMethodTypes: [String]
}

