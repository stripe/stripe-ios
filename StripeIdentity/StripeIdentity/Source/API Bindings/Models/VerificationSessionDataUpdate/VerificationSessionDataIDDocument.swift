//
//  VerificationSessionDataIDDocument.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationSessionDataIDDocument: StripeEncodable, Equatable {

    enum DocumentType: String, Encodable, CaseIterable, Equatable {
        case passport
        case drivingLicense = "driving_license"
        case idCard = "id_card"
    }

    let type: DocumentType?
    let front: String?
    let back: String?

    var _additionalParametersStorage: NonEncodableParameters?
}
