//
//  VerificationPageDataDOB.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataDOB: StripeEncodable, Equatable {

    let day: String?
    let month: String?
    let year: String?

    var _additionalParametersStorage: NonEncodableParameters?
}
