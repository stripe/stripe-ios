//
//  LinkedAccountSession.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation

public struct LinkedAccountSession {
    let id: String
    let object: String
    let clientSecret: String
    let livemode: Bool
    let linkedAccounts: [LinkedAccount]
}
