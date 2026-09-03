//
//  AdditionalKYCQuestionnaire.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A questionnaire used to collect information for an additional KYC requirement.
struct AdditionalKYCQuestionnaire: Decodable, Equatable {

    /// A question displayed as part of an additional KYC questionnaire.
    struct Question: Decodable, Equatable {

        /// The kind of answer accepted by an additional KYC question.
        enum AnswerType: Decodable, Equatable {

            /// A free-form text answer.
            case freeText

            /// An answer type value that this SDK version does not recognize.
            case unknown(String)

            // MARK: - Decodable

            init(from decoder: Decoder) throws {
                switch try decoder.singleValueContainer().decode(String.self) {
                case "free_text":
                    self = .freeText
                case let value:
                    self = .unknown(value)
                }
            }
        }

        /// The API identifier used when submitting the answer.
        let id: String

        /// The localized question displayed to the customer.
        let prompt: String

        /// The kind of answer the question accepts.
        let answerType: AnswerType

        /// Whether the customer must answer the question before submitting.
        let required: Bool

        // MARK: - Decodable

        private enum CodingKeys: String, CodingKey {
            case id
            case prompt
            case answerType = "answer_type"
            case required
        }
    }

    /// The questions to present to the customer.
    let questions: [Question]
}
