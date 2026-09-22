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

        /// Examples of documents in this category.
        let description: String
    }

    /// The document subtypes that the customer may provide.
    let acceptedSubtypes: [DocumentSubtype]

    /// The file extensions accepted for uploaded documents.
    let acceptedFormats: [String]

    /// The maximum size of each file, in bytes.
    let maxFileSizeBytes: Int

    /// The minimum number of distinct document types the customer must provide.
    let minDocumentTypes: Int

    /// The maximum number of distinct document types the customer may provide.
    let maxDocumentTypes: Int

    /// Display text describing the accepted file formats and per-file size limit.
    let fileRequirements: String

    /// Localized instructions to display while collecting documents.
    let instructions: [String]

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case acceptedSubtypes = "accepted_subtypes"
        case acceptedFormats = "accepted_formats"
        case maxFileSizeBytes = "max_file_size_bytes"
        case minDocumentTypes = "min_document_types"
        case maxDocumentTypes = "max_document_types"
        case fileRequirements = "file_requirements"
        case instructions
    }
}
