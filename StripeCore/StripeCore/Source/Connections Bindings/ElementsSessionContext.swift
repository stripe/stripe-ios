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

    /// These fields will be used to prefill the Financial Connections Link Login pane.
    @_spi(STP) public struct PrefillDetails {
        @_spi(STP) public let email: String?
        @_spi(STP) public let phoneNumber: String?

        @_spi(STP) public init(email: String?, phoneNumber: String?) {
            self.email = email
            self.phoneNumber = phoneNumber
        }
    }

    @_spi(STP) public let amount: Int?
    @_spi(STP) public let currency: String?
    @_spi(STP) public let prefillDetails: PrefillDetails?
    @_spi(STP) public let intentId: IntentID?
    @_spi(STP) public let linkMode: LinkMode?
    @_spi(STP) public let billingAddress: BillingAddress?

    @_spi(STP) public init(
        amount: Int?,
        currency: String?,
        prefillDetails: PrefillDetails?,
        intentId: IntentID?,
        linkMode: LinkMode?,
        billingAddress: BillingAddress?
    ) {
        self.amount = amount
        self.currency = currency
        self.prefillDetails = prefillDetails
        self.intentId = intentId
        self.linkMode = linkMode
        self.billingAddress = billingAddress
    }
}
