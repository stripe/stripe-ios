//
//  VerificationPageCollectedData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageCollectedData: Encodable, Equatable {

        private(set) var biometricConsent: Bool?
        private(set) var face: VerificationPageDataFace?
        private(set) var idDocumentBack: VerificationPageDataDocumentFileData?
        private(set) var idDocumentFront: VerificationPageDataDocumentFileData?
        private(set) var idDocumentType: DocumentType?
        private(set) var idNumber: VerificationPageDataIdNumber?
        private(set) var dob: VerificationPageDataDob?
        private(set) var name: VerificationPageDataName?
        private(set) var address: RequiredInternationalAddress?

        init(
            biometricConsent: Bool? = nil,
            face: VerificationPageDataFace? = nil,
            idDocumentBack: VerificationPageDataDocumentFileData? = nil,
            idDocumentFront: VerificationPageDataDocumentFileData? = nil,
            idDocumentType: DocumentType? = nil,
            idNumber: VerificationPageDataIdNumber? = nil,
            dob: VerificationPageDataDob? = nil,
            name: VerificationPageDataName? = nil,
            address: RequiredInternationalAddress? = nil
        ) {
            self.biometricConsent = biometricConsent
            self.face = face
            self.idDocumentBack = idDocumentBack
            self.idDocumentFront = idDocumentFront
            self.idDocumentType = idDocumentType
            self.idNumber = idNumber
            self.dob = dob
            self.name = name
            self.address = address
        }
    }
}

/// All mutating functions needs to pass all values explicitly to the new object, as the default value would be nil.
extension StripeAPI.VerificationPageCollectedData {
    /// Returns a new `VerificationPageCollectedData`, merging the data from this
    /// one with the provided one.
    func merging(
        _ otherData: StripeAPI.VerificationPageCollectedData
    ) -> StripeAPI.VerificationPageCollectedData {
        return StripeAPI.VerificationPageCollectedData(
            biometricConsent: otherData.biometricConsent ?? self.biometricConsent,
            face: otherData.face ?? self.face,
            idDocumentBack: otherData.idDocumentBack ?? self.idDocumentBack,
            idDocumentFront: otherData.idDocumentFront ?? self.idDocumentFront,
            idDocumentType: otherData.idDocumentType ?? self.idDocumentType,
            idNumber: otherData.idNumber ?? self.idNumber,
            dob: otherData.dob ?? self.dob,
            name: otherData.name ?? self.name,
            address: otherData.address ?? self.address
        )
    }

    /// Merges the data from the provided `VerificationPageCollectedData` into this one.
    mutating func merge(_ otherData: StripeAPI.VerificationPageCollectedData) {
        self = self.merging(otherData)
    }

    mutating func clearData(field: StripeAPI.VerificationPageFieldType) {
        switch field {
        case .biometricConsent:
            self.biometricConsent = nil
        case .face:
            self.face = nil
        case .idDocumentBack:
            self.idDocumentBack = nil
        case .idDocumentFront:
            self.idDocumentFront = nil
        case .idDocumentType:
            self.idDocumentType = nil
        case .idNumber:
            self.idNumber = nil
        case .dob:
            self.dob = nil
        case .name:
            self.name = nil
        case .address:
            self.address = nil
        }
    }

    /// Helper to determine the front document score for analytics purposes
    var frontDocumentScore: TwoDecimalFloat? {
        switch idDocumentType {
        case .drivingLicense,
            .idCard:
            return idDocumentFront?.frontCardScore
        case .passport:
            return idDocumentFront?.passportScore
        case .none:
            return nil
        }
    }

    var collectedTypes: Set<StripeAPI.VerificationPageFieldType> {
        var ret = Set<StripeAPI.VerificationPageFieldType>()
        if self.biometricConsent != nil {
            ret.insert(.biometricConsent)
        }
        if self.face != nil {
            ret.insert(.face)
        }
        if self.idDocumentBack != nil {
            ret.insert(.idDocumentBack)
        }
        if self.idDocumentFront != nil {
            ret.insert(.idDocumentFront)
        }
        if self.idDocumentType != nil {
            ret.insert(.idDocumentType)
        }
        if self.idNumber != nil {
            ret.insert(.idNumber)
        }
        if self.dob != nil {
            ret.insert(.dob)
        }
        if self.name != nil {
            ret.insert(.name)
        }
        if self.address != nil {
            ret.insert(.address)
        }
        return ret
    }
}
