//
//  FulfillKYCRequirementsRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/fulfill_kyc_requirements` endpoint.
struct FulfillKYCRequirementsRequest: Encodable {

    /// Documents and additional information submitted for one KYC requirement.
    struct Requirement: Encodable {

        /// The liquidity provider that requested the information.
        let requestedBy: String

        /// Uploaded files grouped by the selected document subtype.
        let documents: [Document]

        /// Additional information collected with the documents.
        let additionalRequirements: AdditionalRequirements?

        // MARK: - Encodable

        private enum CodingKeys: String, CodingKey {
            case requestedBy = "requested_by"
            case documents
            case additionalRequirements = "additional_requirements"
        }
    }

    /// References to uploaded files for one document subtype.
    struct Document: Encodable, Equatable {

        /// The specific document subtype selected by the customer.
        let documentSubtype: String

        /// The identifiers returned after uploading the document files.
        let fileIds: [String]

        // MARK: - Encodable

        private enum CodingKeys: String, CodingKey {
            case documentSubtype = "document_subtype"
            case fileIds = "file_ids"
        }
    }

    /// Information submitted alongside a requirement's documents.
    struct AdditionalRequirements: Encodable {

        /// Answers collected for the requirement's questionnaire.
        let questionnaire: AdditionalKYCFulfillmentQuestionnaire
    }

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Fulfillment payloads keyed by the machine-readable requirement name.
    let requirements: [String: Requirement]
}
