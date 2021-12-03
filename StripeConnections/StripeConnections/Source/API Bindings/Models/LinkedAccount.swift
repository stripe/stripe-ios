//
//  LinkedAccount.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation

public struct LinkedAccount {
    public let id: String
    public let displayName: String
    public let institutionName: String
    public let last4: String
    public let status: String
    public let supportedPaymentMethodTypes: [String]
}

