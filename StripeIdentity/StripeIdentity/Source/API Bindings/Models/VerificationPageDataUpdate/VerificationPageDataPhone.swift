//
//  VerificationPageDataPhone.swift
//  StripeIdentity
//
//  Created by Chen Cen on 6/12/23.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

extension StripeAPI {
    struct VerificationPageDataPhone: Encodable, Equatable {
        let country: String?
        let phoneNumber: String?
    }
}
