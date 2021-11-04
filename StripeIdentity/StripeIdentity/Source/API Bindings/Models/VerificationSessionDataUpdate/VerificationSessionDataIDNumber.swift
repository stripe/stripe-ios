//
//  VerificationSessionDataIDNumber.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataIDNumber: StripeEncodable, Equatable {

    let country: String?
    let partialValue: String?
    let value: String?

    var _additionalParametersStorage: NonEncodableParameters?
}
