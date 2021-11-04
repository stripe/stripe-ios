//
//  VerificationSessionDataUpdate.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataUpdate: StripeEncodable, Equatable {

    struct CollectedData: StripeEncodable, Equatable {

        let individual: VerificationSessionDataIndividual

        var _additionalParametersStorage: NonEncodableParameters?
    }

    let collectedData: CollectedData

    var _additionalParametersStorage: NonEncodableParameters?
}
