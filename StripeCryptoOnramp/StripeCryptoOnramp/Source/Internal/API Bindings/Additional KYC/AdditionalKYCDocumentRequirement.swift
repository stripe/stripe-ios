//
//  AdditionalKYCDocumentRequirement.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// The API-provided configuration for collecting documents for an additional KYC requirement.
struct AdditionalKYCDocumentRequirement: Decodable, Equatable {

    /// A document subtype that can satisfy an additional KYC document requirement.
    struct DocumentSubtype: Decodable, Equatable {

        /// The API identifier submitted for the document subtype.
        let id: String

        /// The localized name displayed for the document subtype.
        let label: String
    }

    /// Information that must be collected in addition to the primary KYC submission.
    struct AdditionalRequirements: Decodable, Equatable {

        /// A questionnaire that must be completed with the primary submission.
        let questionnaire: AdditionalKYCQuestionnaire?
    }

    /// The document subtypes that the customer may provide.
    let acceptedSubtypes: [DocumentSubtype]

    /// The file extensions accepted for uploaded documents.
    let acceptedFormats: [String]

    /// The minimum number of documents the customer must provide.
    let minDocuments: Int

    /// Localized instructions to display while collecting documents.
    let instructions: [String]

    /// Additional information that must be collected with the documents.
    let additionalRequirements: AdditionalRequirements?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case acceptedSubtypes = "accepted_subtypes"
        case acceptedFormats = "accepted_formats"
        case minDocuments = "min_documents"
        case instructions
        case additionalRequirements = "additional_requirements"
    }
}
