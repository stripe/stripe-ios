//
//  VerificationPageDataFace.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataFace: StripeEncodable, Equatable {

    let image: String?

    var _additionalParametersStorage: NonEncodableParameters?
}
