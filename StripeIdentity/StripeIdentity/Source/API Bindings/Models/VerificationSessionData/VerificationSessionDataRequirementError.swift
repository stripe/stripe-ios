//
//  VerificationSessionDataRequirementError.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataRequirementError: StripeDecodable, Equatable {
    typealias Requirement = VerificationPageRequirements.Missing

    enum Code: String, StripeEnumCodable, Equatable {
        case consentDeclined = "consent_declined"
        case underSupportedAge = "under_supported_age"
        case countryNotSupported = "country_not_supported"

        case unparsable
    }

    let code: Code
    let requirement: Requirement
    let title: String
    let body: String
    let buttonText: String

    var _allResponseFieldsStorage: NonEncodableParameters?
}
