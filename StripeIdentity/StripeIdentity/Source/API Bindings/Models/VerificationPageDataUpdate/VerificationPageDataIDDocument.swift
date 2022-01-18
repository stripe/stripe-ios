//
//  VerificationPageDataIDDocument.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataIDDocument: StripeEncodable, Equatable {

    enum DocumentType: String, Encodable, CaseIterable, Equatable {
        case passport
        case drivingLicense = "driving_license"
        case idCard = "id_card"
    }

    let back: VerificationPageDataDocumentFileData?
    let front: VerificationPageDataDocumentFileData?
    let type: DocumentType?

    var _additionalParametersStorage: NonEncodableParameters?
}
