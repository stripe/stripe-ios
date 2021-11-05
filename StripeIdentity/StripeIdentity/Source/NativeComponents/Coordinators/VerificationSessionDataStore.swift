//
//  VerificationSessionDataStore.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

/// A local persistance layer for user input data
final class VerificationSessionDataStore {

    var biometricConsent: Bool? = nil

    /// Convertes the data store into an API object
    var toAPIModel: VerificationSessionDataUpdate {
        return .init(
            collectedData: .init(
                individual: .init(
                    address: nil,
                    consent: .init(
                        train: nil,
                        biometric: biometricConsent,
                        _additionalParametersStorage: nil
                    ),
                    dob: nil,
                    email: nil,
                    face: nil,
                    idDocument: nil,
                    idNumber: nil,
                    name: nil,
                    phoneNumber: nil,
                    _additionalParametersStorage: nil
                ),
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        )
    }
}
