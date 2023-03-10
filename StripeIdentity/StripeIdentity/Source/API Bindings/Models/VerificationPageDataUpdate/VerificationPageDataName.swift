//
//  VerificationPageDataName.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/27/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageDataName: Encodable, Equatable {
        let firstName: String?
        let lastName: String?
    }
}
