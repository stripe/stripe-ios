//
//  ElementsSessionContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-25.
//

import Foundation

/// Contains elements session context useful for the Financial Connections SDK.
@_spi(STP) public struct ElementsSessionContext {
    @_spi(STP) @frozen public enum IntentID {
        case payment(String)
        case setup(String)
    }

    @_spi(STP) public let amount: Int?
    @_spi(STP) public let currency: String?
    @_spi(STP) public let intentId: IntentID?
    @_spi(STP) public let linkMode: LinkMode?
    @_spi(STP) public let email: String?

    @_spi(STP) public init(
        amount: Int?,
        currency: String?,
        intentId: IntentID?,
        linkMode: LinkMode?,
        email: String? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.intentId = intentId
        self.linkMode = linkMode
        self.email = email
    }
}

@_spi(STP) public extension ElementsSessionContext {
    init(email: String?) {
        self.init(amount: nil, currency: nil, intentId: nil, linkMode: nil, email: email)
    }
}
