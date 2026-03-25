//
//  PrefillDetails.swift
//  StripeCore
//
//  Created by Mat Schmid on 2025-03-27.
//

import Foundation

/// The fields used to prefill the Link Login pane.
@_spi(STP) public protocol PrefillData {
    var email: String? { get }
    var phone: String? { get }
    var countryCode: String? { get }
}

/// An email and an unformatted phone number + country code will be passed to the web flow.
@_spi(STP) public struct WebPrefillDetails {
    @_spi(STP) public let email: String?
    @_spi(STP) public let phone: String?
    @_spi(STP) public let countryCode: String?

    @_spi(STP) public init(
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
    @_spi(STP) public var phone: String? { unformattedPhoneNumber }
}
