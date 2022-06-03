//
//  VerificationPageClearData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/2/22.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageClearData: Encodable, Equatable {
        let biometricConsent: Bool?
        let idDocumentBack: Bool?
        let idDocumentFront: Bool?
        let idDocumentType: Bool?
    }
}

extension StripeAPI.VerificationPageClearData {
    init(clearFields fields: Set<StripeAPI.VerificationPageFieldType>) {
        self.init(
            biometricConsent: fields.contains(.biometricConsent),
            idDocumentBack: fields.contains(.idDocumentBack),
            idDocumentFront: fields.contains(.idDocumentFront),
            idDocumentType: fields.contains(.idDocumentType)
        )
    }
}
