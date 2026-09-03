//
//  FulfillAdditionalKYCRequirementResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Decodable model returned by the `/v1/crypto/internal/fulfill_additional_kyc_requirement` endpoint.
struct FulfillAdditionalKYCRequirementResponse: Decodable, Equatable {

    /// The unique identifier for the submission.
    let id: String

    /// The API object type associated with the submission.
    let object: String

    /// The liquidity provider that requested the submitted information.
    let liquidityProvider: String

    /// The kind of information included in the submission.
    let submissionType: AdditionalKYCSubmissionType

    /// The documents included in the submission.
    let documents: [FulfillAdditionalKYCRequirementResponseDocument]?

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
