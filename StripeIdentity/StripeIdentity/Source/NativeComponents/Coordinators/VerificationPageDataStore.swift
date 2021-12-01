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

    struct DocumentImage: Equatable {
        let image: UIImage
        let fileId: String
    }

    var biometricConsent: Bool? = nil
    var idDocumentType: VerificationPageDataIDDocument.DocumentType? = nil

    var frontDocumentImage: DocumentImage? = nil
    var backDocumentImage: DocumentImage? = nil

    /// Convertes the data store into an API object
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
                    front: frontDocumentImage?.fileId,
                    back: backDocumentImage?.fileId,
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
