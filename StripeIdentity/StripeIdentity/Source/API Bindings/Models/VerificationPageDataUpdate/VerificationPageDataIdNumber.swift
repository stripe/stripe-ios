//
//  VerificationPageDataIdNumber.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/27/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageDataIdNumber: Encodable, Equatable {
        let country: String?
        let partialValue: String?
        let value: String?
    }
}
