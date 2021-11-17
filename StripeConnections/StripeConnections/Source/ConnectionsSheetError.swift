//
//  ConnectionsSheetError.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation

public enum ConnectionsSheetError {
    // Client secret is malformed or does not correspond to a valid token.
    case invalidClientSecret
    // An unknown error occurred
    case unknown(debugDescription: String)
}
