//
//  VerificationPageCollectedData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageCollectedData: StripeEncodable, Equatable {

    var consent: VerificationPageDataConsent?
    var idDocument: VerificationPageDataIDDocument?

    var _additionalParametersStorage: NonEncodableParameters?
}


extension VerificationPageCollectedData {
    init(biometricConsent: Bool) {
        self.init(
            consent: .init(
                biometric: biometricConsent,
                _additionalParametersStorage: nil
            ),
            idDocument: nil,
            _additionalParametersStorage: nil
        )
    }

    init(idDocumentType: DocumentType) {
        self.init(
            consent: nil,
            idDocument: .init(
                back: nil,
                front: nil,
                type: idDocumentType,
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        )
    }

    init(
        idDocumentFront: VerificationPageDataDocumentFileData?,
        idDocumentBack: VerificationPageDataDocumentFileData?
    ) {
        self.init(
            consent: nil,
            idDocument: .init(
                back: idDocumentBack,
                front: idDocumentFront,
                type: nil,
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        )
    }

    /**
     Returns a new `VerificationPageCollectedData`, merging the data from this
     one with the provided one.
     */
    func merging(_ otherData: VerificationPageCollectedData) -> VerificationPageCollectedData {
        return VerificationPageCollectedData(
            consent: VerificationPageDataConsent(
                biometric: otherData.consent?.biometric ?? self.consent?.biometric,
                _additionalParametersStorage: nil
            ),
            idDocument: VerificationPageDataIDDocument(
                back: otherData.idDocument?.back ?? self.idDocument?.back,
                front: otherData.idDocument?.front ?? self.idDocument?.front,
                type: otherData.idDocument?.type ?? self.idDocument?.type,
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        )
    }

    /**
     Merges the data from the provided `VerificationPageCollectedData` into this one.
     */
    mutating func merge(_ otherData: VerificationPageCollectedData) {
        self = self.merging(otherData)
    }
}
