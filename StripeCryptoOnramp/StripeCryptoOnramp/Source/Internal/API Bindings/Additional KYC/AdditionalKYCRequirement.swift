//
//  AdditionalKYCRequirement.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A partner-specific KYC requirement returned for an authenticated customer.
struct AdditionalKYCRequirement: Decodable, Equatable {

    /// A party that may be responsible for the next action on an additional KYC requirement.
    enum ActionParty: Decodable, Equatable {

        /// The customer must provide additional information.
        case user

        /// The liquidity partner must review or process the submitted information.
        case partner

        /// Stripe must review or process the submitted information.
        case stripe

        /// An action party value that this SDK version does not recognize.
        case unknown(String)

        // MARK: - Decodable

        init(from decoder: Decoder) throws {
            switch try decoder.singleValueContainer().decode(String.self) {
            case "user":
                self = .user
            case "partner":
                self = .partner
            case "stripe":
                self = .stripe
            case let value:
                self = .unknown(value)
            }
        }
    }

    /// An error from a previous attempt to fulfill an additional KYC requirement.
    struct RequirementError: Decodable, Equatable {

        /// A machine-readable value identifying the error.
        let code: String

        /// A localized explanation of the error.
        let message: String
    }

    /// A value describing the information the customer must provide (e.g. `proof_of_address`, `source_of_funds`).
    let description: String

    /// The liquidity provider that requested the information.
    let requestedBy: String

    /// The party currently responsible for acting on the requirement.
    let awaitingActionFrom: ActionParty

    /// The kind of information the customer must submit.
    let submissionType: AdditionalKYCSubmissionType

    /// Errors from previous attempts to fulfill the requirement.
    let errors: [RequirementError]

    /// Document-specific collection details, when documents are required.
    let document: AdditionalKYCDocumentRequirement?

    /// Questionnaire-specific collection details, when answers are required.
    let questionnaire: AdditionalKYCQuestionnaire?

    /// The questionnaire associated directly with the requirement or nested under its document details.
    var effectiveQuestionnaire: AdditionalKYCQuestionnaire? {
        // TODO: Confirm whether questionnaire-only requirements return a top-level questionnaire and whether both locations can be populated.
        questionnaire ?? document?.additionalRequirements?.questionnaire
    }

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case description
        case requestedBy = "requested_by"
        case awaitingActionFrom = "awaiting_action_from"
        case submissionType = "submission_type"
        case errors
        case document
        case questionnaire
    }
}
