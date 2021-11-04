//
//  VerificationSessionDataConsent.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataConsent: StripeEncodable, Equatable {

    let train: Bool?
    let biometric: Bool?

    var _additionalParametersStorage: NonEncodableParameters?
}
