//
//  VerificationPageDataRequirements.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataRequirements: StripeDecodable, Equatable {

    typealias Missing = VerificationPageRequirements.Missing

    let missing: [Missing]
    let errors: [VerificationPageDataRequirementError]

    var _allResponseFieldsStorage: NonEncodableParameters?
}
