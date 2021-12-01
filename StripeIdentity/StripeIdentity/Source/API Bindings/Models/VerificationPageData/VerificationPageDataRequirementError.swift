//
//  VerificationPageDataRequirementError.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataRequirementError: StripeDecodable, Equatable {
    typealias Requirement = VerificationPageRequirements.Missing

    let requirement: Requirement
    let title: String
    let body: String
    let buttonText: String

    var _allResponseFieldsStorage: NonEncodableParameters?
}
