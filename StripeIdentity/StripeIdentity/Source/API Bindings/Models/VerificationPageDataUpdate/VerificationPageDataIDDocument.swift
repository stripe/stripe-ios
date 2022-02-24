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
        // NOTE: The declaration order determines the default order these
        // are displayed in the UI on the document selection screen

        case drivingLicense = "driving_license"
        case idCard = "id_card"
        case passport
    }

    let back: VerificationPageDataDocumentFileData?
    let front: VerificationPageDataDocumentFileData?
    let type: DocumentType?

    var _additionalParametersStorage: NonEncodableParameters?
}
