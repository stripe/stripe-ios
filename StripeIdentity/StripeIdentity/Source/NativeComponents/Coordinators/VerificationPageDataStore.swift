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
    var idDocumentType: DocumentType? = nil

    var frontDocumentFileData: VerificationPageDataDocumentFileData? = nil
    var backDocumentFileData: VerificationPageDataDocumentFileData? = nil

    /// Converts the data store into an API object
    var toAPIModel: VerificationPageDataUpdate {
        return .init(
            collectedData: .init(
                consent: .init(
                    biometric: biometricConsent,
                    _additionalParametersStorage: nil
                ),
                idDocument: .init(
                    back: backDocumentFileData,
                    front: frontDocumentFileData,
                    type: idDocumentType,
                    _additionalParametersStorage: nil
                ),
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        )
    }
}
