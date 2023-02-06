//
//  VerificationPageDataDob.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/27/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageDataDob: Encodable, Equatable {
        let day: String?
        let month: String?
        let year: String?
    }
}
