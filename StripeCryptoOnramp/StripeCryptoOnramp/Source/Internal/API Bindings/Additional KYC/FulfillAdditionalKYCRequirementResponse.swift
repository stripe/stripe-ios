//
//  FulfillAdditionalKYCRequirementResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Decodable model returned by the `/v1/crypto/internal/fulfill_additional_kyc_requirement` endpoint.
struct FulfillAdditionalKYCRequirementResponse: Decodable, Equatable {

    /// A document included in a response after fulfilling an additional KYC requirement.
    struct Document: Decodable, Equatable {

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

    /// The unique identifier for the submission.
    let id: String

    /// The API object type associated with the submission.
    let object: String

    /// The liquidity provider that requested the submitted information.
    let liquidityProvider: String

    /// The kind of information included in the submission.
    let submissionType: AdditionalKYCSubmissionType

    /// The documents included in the submission.
    let documents: [Document]?

    /// The questionnaire answers included in the submission.
    let questionnaire: AdditionalKYCFulfillmentQuestionnaire?

    /// The verification status of the submission.
    let status: String

    /// The time at which the submission was created.
    let created: Date

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case id
        case object
        case liquidityProvider = "liquidity_provider"
        case submissionType = "submission_type"
        case documents
        case questionnaire
        case status
        case created
    }
}
