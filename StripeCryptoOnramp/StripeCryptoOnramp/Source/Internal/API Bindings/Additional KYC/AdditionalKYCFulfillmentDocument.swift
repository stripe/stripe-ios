//
//  AdditionalKYCFulfillmentDocument.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// References to uploaded files submitted for an additional KYC document requirement.
struct AdditionalKYCFulfillmentDocument: Codable, Equatable {

    /// The general kind of document being submitted.
    let documentType: String

    /// The specific document subtype selected by the customer.
    let documentSubtype: String?

    /// The identifiers returned after uploading the document files.
    let fileIds: [String]

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case documentSubtype = "document_subtype"
        case fileIds = "file_ids"
    }
}
