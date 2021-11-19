//
//  ConnectionsSheetError.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

public enum ConnectionsSheetError: Error {
    /// An unknown error.
    case unknown(debugDescription: String)

    /// Localized description of the error
    public var localizedDescription: String {
        return NSError.stp_unexpectedErrorMessage()
    }
}
