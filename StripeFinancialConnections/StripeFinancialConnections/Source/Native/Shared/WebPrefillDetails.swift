//
//  WebPrefillDetails.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-27.
//

import Foundation
@_spi(STP) import StripeCore

/// The fields used to prefill the Link Login pane.
protocol PrefillData {
    var email: String? { get }
    var phone: String? { get }
    var countryCode: String? { get }
}

/// An email and an unformatted phone number + country code will be passed to the web flow.
struct WebPrefillDetails {
    let email: String?
    let phone: String?
    let countryCode: String?

    init(email: String?, phone: String? = nil, countryCode: String? = nil) {
        self.email = email
        self.phone = phone
        self.countryCode = countryCode
    }
}

extension WebPrefillDetails: PrefillData {}
extension ElementsSessionContext.PrefillDetails: PrefillData {
    var phone: String? { unformattedPhoneNumber }
}
