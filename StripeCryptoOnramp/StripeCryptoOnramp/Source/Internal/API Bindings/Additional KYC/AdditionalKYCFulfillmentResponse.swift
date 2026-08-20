//
//  AdditionalKYCFulfillmentResponse.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A response returned after submitting information for an additional KYC requirement.
struct AdditionalKYCFulfillmentResponse: Decodable, Equatable {

    /// The unique identifier for the submission.
    let id: String

    /// The API object type associated with the submission.
    let object: String?

    /// The liquidity provider that requested the submitted information.
    let liquidityProvider: String?

    /// The kind of information included in the submission.
    let submissionType: AdditionalKYCSubmissionType?

    /// The documents included in the submission.
    let documents: [AdditionalKYCFulfillmentDocument]?

    /// The questionnaire answers included in the submission.
    let questionnaire: AdditionalKYCFulfillmentQuestionnaire?

    // TODO: Confirm whether the fulfillment response includes a status. The
    // current API design documents `submitted_at` but pending-verification behavior needs status.

    /// The verification status of the submission.
    let status: String?

    /// The time at which the information was submitted.
    let submittedAt: Date?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case id
        case object
        case liquidityProvider = "liquidity_provider"
        case submissionType = "submission_type"
        case documents
        case questionnaire
        case status
        case submittedAt = "submitted_at"
    }
}
