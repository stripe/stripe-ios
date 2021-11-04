//
//  VerificationSessionDataIndividual.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataIndividual: StripeEncodable, Equatable {

    let address: VerificationSessionDataAddress?
    let consent: VerificationSessionDataConsent?
    let dob: VerificationSessionDataDOB?
    let email: String?
    let face: VerificationSessionDataFace?
    let idDocument: VerificationSessionDataIDDocument?
    let idNumber: VerificationSessionDataIDNumber?
    let name: VerificationSessionDataName?
    let phoneNumber: String?

    var _additionalParametersStorage: NonEncodableParameters?
}
