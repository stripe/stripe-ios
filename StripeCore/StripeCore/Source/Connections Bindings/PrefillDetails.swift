//
//  PrefillDetails.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-03-27.
//

import Foundation

/// The fields used to prefill the Link Login pane.
@_spi(InternalOnlyAPI) public protocol PrefillData {
    var email: String? { get }
    var phone: String? { get }
    var countryCode: String? { get }
}

/// An email and an unformatted phone number + country code will be passed to the web flow.
@_spi(InternalOnlyAPI) public struct WebPrefillDetails {
    @_spi(InternalOnlyAPI) public let email: String?
    @_spi(InternalOnlyAPI) public let phone: String?
    @_spi(InternalOnlyAPI) public let countryCode: String?

    @_spi(InternalOnlyAPI) public init(
        email: String?,
        phone: String? = nil,
        countryCode: String? = nil
    ) {
        self.email = email
        self.phone = phone
        self.countryCode = countryCode
    }
}

extension WebPrefillDetails: PrefillData {}
extension ElementsSessionContext.PrefillDetails: PrefillData {
    @_spi(InternalOnlyAPI) public var phone: String? { unformattedPhoneNumber }
}
