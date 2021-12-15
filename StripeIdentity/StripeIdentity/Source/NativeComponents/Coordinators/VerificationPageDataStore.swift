//
//  VerificationPageDataStore.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import UIKit
@_spi(STP) import StripeCore

/// A local persistence layer for user input data
final class VerificationPageDataStore {

    var biometricConsent: Bool? = nil
    var idDocumentType: VerificationPageDataIDDocument.DocumentType? = nil

    var frontDocumentFileData: VerificationPageDataDocumentFileData? = nil
    var backDocumentFileData: VerificationPageDataDocumentFileData? = nil

    /// Converts the data store into an API object
    var toAPIModel: VerificationPageDataUpdate {
        return .init(
            collectedData: .init(
                address: nil,
                consent: .init(
                    train: nil,
                    biometric: biometricConsent,
                    _additionalParametersStorage: nil
                ),
                dob: nil,
                email: nil,
                face: nil,
                idDocument: .init(
                    type: idDocumentType,
                    front: frontDocumentFileData,
                    back: backDocumentFileData,
                    _additionalParametersStorage: nil
                ),
                idNumber: nil,
                name: nil,
                phoneNumber: nil,
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        )
    }
}
