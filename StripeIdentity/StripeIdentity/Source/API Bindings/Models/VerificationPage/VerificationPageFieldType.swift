//
//  VerificationPageFieldType.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/26/22.
//

import Foundation

enum VerificationPageFieldType: String, Codable, Equatable, CaseIterable {
    case biometricConsent = "biometric_consent"
    case idDocumentBack = "id_document_back"
    case idDocumentFront = "id_document_front"
    case idDocumentType = "id_document_type"
}
