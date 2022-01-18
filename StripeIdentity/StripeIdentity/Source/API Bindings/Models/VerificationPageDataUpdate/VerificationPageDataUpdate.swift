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

        let consent: VerificationPageDataConsent?
        let idDocument: VerificationPageDataIDDocument?

        var _additionalParametersStorage: NonEncodableParameters?
    }

    let collectedData: CollectedData

    var _additionalParametersStorage: NonEncodableParameters?
}
