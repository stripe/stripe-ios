//
//  VerificationPageDataUpdate.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataUpdate: StripeEncodable, Equatable {

    struct CollectedData: StripeEncodable, Equatable {

        let address: VerificationPageDataAddress?
        let consent: VerificationPageDataConsent?
        let dob: VerificationPageDataDOB?
        let email: String?
        let face: VerificationPageDataFace?
        let idDocument: VerificationPageDataIDDocument?
        let idNumber: VerificationPageDataIDNumber?
        let name: VerificationPageDataName?
        let phoneNumber: String?

        var _additionalParametersStorage: NonEncodableParameters?
    }

    let collectedData: CollectedData

    var _additionalParametersStorage: NonEncodableParameters?
}
