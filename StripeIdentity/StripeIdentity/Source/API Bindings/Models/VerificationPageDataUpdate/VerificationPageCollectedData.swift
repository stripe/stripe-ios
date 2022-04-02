//
//  VerificationPageCollectedData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageCollectedData: StripeEncodable, Equatable {

    let biometricConsent: Bool?
    let idDocumentBack: VerificationPageDataDocumentFileData?
    let idDocumentFront: VerificationPageDataDocumentFileData?
    let idDocumentType: DocumentType?

    var _additionalParametersStorage: NonEncodableParameters?

    init(
        biometricConsent: Bool? = nil,
        idDocumentBack: VerificationPageDataDocumentFileData? = nil,
        idDocumentFront: VerificationPageDataDocumentFileData? = nil,
        idDocumentType: DocumentType? = nil
    ) {
        self.biometricConsent = biometricConsent
        self.idDocumentBack = idDocumentBack
        self.idDocumentFront = idDocumentFront
        self.idDocumentType = idDocumentType
        self._additionalParametersStorage = nil
    }
}

extension VerificationPageCollectedData {
    /**
     Returns a new `VerificationPageCollectedData`, merging the data from this
     one with the provided one.
     */
    func merging(_ otherData: VerificationPageCollectedData) -> VerificationPageCollectedData {
        return VerificationPageCollectedData(
            biometricConsent: otherData.biometricConsent ?? self.biometricConsent,
            idDocumentBack: otherData.idDocumentBack ?? self.idDocumentBack,
            idDocumentFront: otherData.idDocumentFront ?? self.idDocumentFront,
            idDocumentType: otherData.idDocumentType ?? self.idDocumentType
        )
    }

    /**
     Merges the data from the provided `VerificationPageCollectedData` into this one.
     */
    mutating func merge(_ otherData: VerificationPageCollectedData) {
        self = self.merging(otherData)
    }
}
