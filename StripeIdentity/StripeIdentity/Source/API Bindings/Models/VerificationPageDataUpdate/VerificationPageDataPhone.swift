//
//  VerificationPageDataPhone.swift
//  StripeIdentity
//
//  Created by Chen Cen on 6/12/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageDataPhone: Encodable, Equatable {
        let countryCode: String?
        let number: String?
    }
}
