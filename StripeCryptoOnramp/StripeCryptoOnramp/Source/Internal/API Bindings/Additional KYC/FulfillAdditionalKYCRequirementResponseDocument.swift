//
//  FulfillAdditionalKYCRequirementResponseDocument.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/3/26.
//

import Foundation

/// A document included in a response after fulfilling an additional KYC requirement.
struct FulfillAdditionalKYCRequirementResponseDocument: Decodable, Equatable {

    /// The general kind of document submitted.
    let documentType: String

    /// The specific document subtype selected by the customer.
    let documentSubtype: String?

    /// The identifiers of the uploaded document files.
    let fileIds: [String]

    /// The document's verification status.
    let status: String

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case documentSubtype = "document_subtype"
        case fileIds = "file_ids"
        case status
    }
}
