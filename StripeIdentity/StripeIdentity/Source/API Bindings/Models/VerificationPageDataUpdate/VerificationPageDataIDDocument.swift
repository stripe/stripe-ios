//
//  VerificationPageDataIDDocument.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataIDDocument: StripeEncodable, Equatable {

    let back: VerificationPageDataDocumentFileData?
    let front: VerificationPageDataDocumentFileData?
    let type: DocumentType?

    var _additionalParametersStorage: NonEncodableParameters?
}
