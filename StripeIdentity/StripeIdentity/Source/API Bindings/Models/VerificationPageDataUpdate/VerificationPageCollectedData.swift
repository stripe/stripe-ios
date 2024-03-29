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
        private(set) var idNumber: VerificationPageDataIdNumber?
        private(set) var dob: VerificationPageDataDob?
        private(set) var name: VerificationPageDataName?
        private(set) var address: RequiredInternationalAddress?
        private(set) var phone: VerificationPageDataPhone?
        private(set) var phoneOtp: String?

        init(
            biometricConsent: Bool? = nil,
            face: VerificationPageDataFace? = nil,
            idDocumentBack: VerificationPageDataDocumentFileData? = nil,
            idDocumentFront: VerificationPageDataDocumentFileData? = nil,
            idNumber: VerificationPageDataIdNumber? = nil,
            dob: VerificationPageDataDob? = nil,
            name: VerificationPageDataName? = nil,
            address: RequiredInternationalAddress? = nil,
            phone: VerificationPageDataPhone? = nil,
            phoneOtp: String? = nil
        ) {
            self.biometricConsent = biometricConsent
            self.face = face
            self.idDocumentBack = idDocumentBack
            self.idDocumentFront = idDocumentFront
            self.idNumber = idNumber
            self.dob = dob
            self.name = name
            self.address = address
            self.phone = phone
            self.phoneOtp = phoneOtp
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
            idNumber: otherData.idNumber ?? self.idNumber,
            dob: otherData.dob ?? self.dob,
            name: otherData.name ?? self.name,
            address: otherData.address ?? self.address,
            phone: otherData.phone ?? self.phone,
            phoneOtp: otherData.phoneOtp ?? self.phoneOtp
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
        case .idNumber:
            self.idNumber = nil
        case .dob:
            self.dob = nil
        case .name:
            self.name = nil
        case .address:
            self.address = nil
        case .phoneNumber:
            self.phone = nil
        case .phoneOtp:
            self.phoneOtp = nil
        }
    }

    /// Helper to determine the front document score for analytics purposes
    var frontDocumentScore: TwoDecimalFloat? {
        // return the larger of the two
        guard let frontCardScore = idDocumentFront?.frontCardScore?.value, let passportScore = idDocumentFront?.passportScore?.value else
        {
            return nil
        }
        if frontCardScore > passportScore {
            return idDocumentFront?.frontCardScore
        } else {
            return idDocumentFront?.passportScore
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
        if self.phone != nil {
            ret.insert(.phoneNumber)
        }
        if self.phoneOtp != nil {
            ret.insert(.phoneOtp)
        }
        return ret
    }
}
