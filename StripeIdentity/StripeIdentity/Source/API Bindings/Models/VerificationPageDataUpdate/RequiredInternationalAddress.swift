//
//  RequiredInternationalAddress.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/27/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct RequiredInternationalAddress: Encodable, Equatable {
        let line1: String
        let line2: String?
        let city: String?
        let postalCode: String?
        let state: String?
        let country: String?
    }
}
