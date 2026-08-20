//
//  AdditionalKYCDocumentRequirement.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// The API-provided configuration for collecting documents for an additional KYC requirement.
struct AdditionalKYCDocumentRequirement: Codable, Equatable {

    /// The document subtypes that the customer may provide.
    let acceptedSubtypes: [AdditionalKYCDocumentSubtype]

    /// The file extensions accepted for uploaded documents.
    let acceptedFormats: [String]

    /// The minimum number of documents the customer must provide.
    let minDocuments: Int

    /// Localized instructions to display while collecting documents.
    let instructions: [String]

    /// Additional information that must be collected with the documents.
    let additionalRequirements: AdditionalKYCAdditionalRequirements?

    /// Creates a document requirement configuration.
    /// - Parameters:
    ///   - acceptedSubtypes: The document subtypes that the customer may provide.
    ///   - acceptedFormats: The file extensions accepted for uploaded documents.
    ///   - minDocuments: The minimum number of documents the customer must provide.
    ///   - instructions: Localized instructions to display while collecting documents.
    ///   - additionalRequirements: Additional information that must be collected with the documents.
    init(
        acceptedSubtypes: [AdditionalKYCDocumentSubtype],
        acceptedFormats: [String],
        minDocuments: Int,
        instructions: [String],
        additionalRequirements: AdditionalKYCAdditionalRequirements? = nil
    ) {
        self.acceptedSubtypes = acceptedSubtypes
        self.acceptedFormats = acceptedFormats
        self.minDocuments = minDocuments
        self.instructions = instructions
        self.additionalRequirements = additionalRequirements
    }

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case acceptedSubtypes = "accepted_subtypes"
        case acceptedFormats = "accepted_formats"
        case minDocuments = "min_documents"
        case instructions
        case additionalRequirements = "additional_requirements"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        acceptedSubtypes = try container.decodeIfPresent([AdditionalKYCDocumentSubtype].self, forKey: .acceptedSubtypes) ?? []
        acceptedFormats = try container.decodeIfPresent([String].self, forKey: .acceptedFormats) ?? []
        minDocuments = try container.decodeIfPresent(Int.self, forKey: .minDocuments) ?? 1
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        additionalRequirements = try container.decodeIfPresent(AdditionalKYCAdditionalRequirements.self, forKey: .additionalRequirements)
    }
}
