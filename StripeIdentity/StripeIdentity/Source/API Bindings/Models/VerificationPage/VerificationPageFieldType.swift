//
//  VerificationPageFieldType.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension StripeAPI {
    enum VerificationPageFieldType: String, Codable, Equatable, CaseIterable {
        case biometricConsent = "biometric_consent"
        case face = "face"
        case idDocumentBack = "id_document_back"
        case idDocumentFront = "id_document_front"
        case idDocumentType = "id_document_type"
        case idNumber = "id_number"
        case dob = "dob"
        case name = "name"
        case address = "address"
    }
}
