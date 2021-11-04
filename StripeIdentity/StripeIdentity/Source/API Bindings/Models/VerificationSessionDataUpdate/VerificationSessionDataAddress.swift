//
//  VerificationSessionDataAddress.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataAddress: StripeEncodable, Equatable {

    let city: String?
    let country: String?
    let line1: String?
    let line2: String?
    let state: String?
    let postalCode: String?

    var _additionalParametersStorage: NonEncodableParameters?
}
