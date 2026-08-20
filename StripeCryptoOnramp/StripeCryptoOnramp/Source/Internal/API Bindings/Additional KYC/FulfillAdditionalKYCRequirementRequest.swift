//
//  FulfillAdditionalKYCRequirementRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/fulfill_additional_kyc_requirement` endpoint.
struct FulfillAdditionalKYCRequirementRequest: Encodable {

    /// Contains credentials required to submit the fulfillment request.
    let credentials: Credentials

    /// The liquidity provider that requested the additional KYC information.
    let liquidityProvider: String

    /// The requirement's submission type, such as `document` or `questionnaire`.
    let submissionType: String

    /// Documents uploaded to fulfill the requirement, grouped by document type and subtype.
    let documents: [AdditionalKYCFulfillmentDocument]?

    /// Answers collected for the requirement's questionnaire.
    let questionnaire: AdditionalKYCFulfillmentQuestionnaire?

    // MARK: - Encodable

    private enum CodingKeys: String, CodingKey {
        case credentials
        case liquidityProvider = "liquidity_provider"
        case submissionType = "submission_type"
        case documents
        case questionnaire
    }
}
