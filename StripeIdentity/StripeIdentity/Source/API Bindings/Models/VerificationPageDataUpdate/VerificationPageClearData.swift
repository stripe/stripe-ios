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
        let face: Bool?
        let idDocumentBack: Bool?
        let idDocumentFront: Bool?
        let idDocumentType: Bool?
    }

    // TODO(mludowise|IDPROD-4030): Remove v1 API models when selfie is production ready
    /// API model compatible with V1 Identity endpoints that won't encode a `face` property
    struct VerificationPageClearDataV1: Encodable, Equatable {
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
            face: fields.contains(.face),
            idDocumentBack: fields.contains(.idDocumentBack),
            idDocumentFront: fields.contains(.idDocumentFront),
            idDocumentType: fields.contains(.idDocumentType)
        )
    }
}
