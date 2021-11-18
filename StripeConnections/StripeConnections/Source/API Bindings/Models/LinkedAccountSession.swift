//
//  LinkedAccountSession.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation

public struct LinkedAccountSession {
    public let id: String
    public let clientSecret: String
    public let linkedAccounts: [LinkedAccount]
}
