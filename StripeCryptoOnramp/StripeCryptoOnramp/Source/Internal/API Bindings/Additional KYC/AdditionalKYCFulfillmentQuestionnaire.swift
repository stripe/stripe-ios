//
//  AdditionalKYCFulfillmentQuestionnaire.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Questionnaire answers submitted for an additional KYC requirement.
struct AdditionalKYCFulfillmentQuestionnaire: Codable, Equatable {

    /// An answer submitted for one additional KYC question.
    struct Answer: Codable, Equatable {

        /// The API identifier of the question being answered.
        let questionId: String

        /// The customer's answer.
        let value: String

        // MARK: - Codable

        private enum CodingKeys: String, CodingKey {
            case questionId = "question_id"
            case value
        }
    }

    /// The customer's answers to the questionnaire.
    let answers: [Answer]
}
