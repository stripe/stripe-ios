//
//  VerificationPageClearData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/2/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
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
        let idNumber: Bool?
        let dob: Bool?
        let name: Bool?
        let address: Bool?
    }
}

extension StripeAPI.VerificationPageClearData {
    init(
        clearFields fields: Set<StripeAPI.VerificationPageFieldType>
    ) {
        self.init(
            biometricConsent: fields.contains(.biometricConsent),
            face: fields.contains(.face),
            idDocumentBack: fields.contains(.idDocumentBack),
            idDocumentFront: fields.contains(.idDocumentFront),
            idDocumentType: fields.contains(.idDocumentType),
            idNumber: fields.contains(.idNumber),
            dob: fields.contains(.dob),
            name: fields.contains(.name),
            address: fields.contains(.address)
        )
    }
}
