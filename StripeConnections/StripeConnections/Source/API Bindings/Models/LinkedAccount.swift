//
//  LinkedAccountResult.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore

public struct LinkedAccountResult: StripeDecodable {
    public let id: String
    public var displayName: String?
    public var institutionName: String?
    public var last4: String?
    public var _allResponseFieldsStorage: NonEncodableParameters?
}

