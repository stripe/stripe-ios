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
    /// An unformatted phone number + country code will be passed to the web flow,
    /// and a formatted phone number will be passed to the native flow.
    @_spi(STP) public struct PrefillDetails {
        @_spi(STP) public let email: String?
        @_spi(STP) public let formattedPhoneNumber: String?
        @_spi(STP) public let unformattedPhoneNumber: String?
        @_spi(STP) public let countryCode: String?

        @_spi(STP) public init(
            email: String?,
            formattedPhoneNumber: String?,
            unformattedPhoneNumber: String?,
            countryCode: String?
        ) {
            self.email = email
            self.formattedPhoneNumber = formattedPhoneNumber
            self.unformattedPhoneNumber = unformattedPhoneNumber
            self.countryCode = countryCode
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
