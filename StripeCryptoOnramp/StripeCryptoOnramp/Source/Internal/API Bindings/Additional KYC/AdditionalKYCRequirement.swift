//
//  AdditionalKYCRequirement.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A partner-specific KYC requirement returned for an authenticated customer.
struct AdditionalKYCRequirement: Decodable, Equatable {

    /// A value describing the information the customer must provide (e.g. `proof_of_address`, `source_of_funds`).
    let description: String

    /// The liquidity provider that requested the information.
    let requestedBy: String

    /// The party currently responsible for acting on the requirement.
    let awaitingActionFrom: AdditionalKYCActionParty

    /// The kind of information the customer must submit.
    let submissionType: AdditionalKYCSubmissionType

    /// Errors from previous attempts to fulfill the requirement.
    let errors: [AdditionalKYCRequirementError]

    /// Document-specific collection details, when documents are required.
    let document: AdditionalKYCDocumentRequirement?

    /// Questionnaire-specific collection details, when answers are required.
    let questionnaire: AdditionalKYCQuestionnaire?

    /// The questionnaire associated directly with the requirement or nested under its document details.
    var effectiveQuestionnaire: AdditionalKYCQuestionnaire? {
        // TODO: Confirm whether questionnaire-only requirements return a top-level questionnaire and whether both locations can be populated.
        questionnaire ?? document?.additionalRequirements?.questionnaire
    }

    /// Creates an additional KYC requirement.
    /// - Parameters:
    ///   - description: A value describing the information the customer must provide (e.g. `proof_of_address`, `source_of_funds`).
    ///   - requestedBy: The liquidity provider that requested the information.
    ///   - awaitingActionFrom: The party currently responsible for acting on the requirement.
    ///   - submissionType: The kind of information the customer must submit.
    ///   - errors: Errors from previous attempts to fulfill the requirement.
    ///   - document: Document-specific collection details, when documents are required.
    ///   - questionnaire: Questionnaire-specific collection details, when answers are required.
    init(
        description: String,
        requestedBy: String,
        awaitingActionFrom: AdditionalKYCActionParty,
        submissionType: AdditionalKYCSubmissionType,
        errors: [AdditionalKYCRequirementError] = [],
        document: AdditionalKYCDocumentRequirement? = nil,
        questionnaire: AdditionalKYCQuestionnaire? = nil
    ) {
        self.description = description
        self.requestedBy = requestedBy
        self.awaitingActionFrom = awaitingActionFrom
        self.submissionType = submissionType
        self.errors = errors
        self.document = document
        self.questionnaire = questionnaire
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
