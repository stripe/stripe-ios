//
//  FulfillAdditionalKYCRequirementRequestDocument.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/3/26.
//

import Foundation

/// References to uploaded files included in a request to fulfill an additional KYC document requirement.
struct FulfillAdditionalKYCRequirementRequestDocument: Encodable, Equatable {

    /// The general kind of document being submitted.
    let documentType: String

    /// The specific document subtype selected by the customer.
    let documentSubtype: String?

    /// The identifiers returned after uploading the document files.
    let fileIds: [String]

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case documentSubtype = "document_subtype"
        case fileIds = "file_ids"
    }
}
