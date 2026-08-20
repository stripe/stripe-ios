//
//  AdditionalKYCQuestion.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A question displayed as part of an additional KYC questionnaire.
struct AdditionalKYCQuestion: Codable, Equatable {

    /// The API identifier used when submitting the answer.
    let id: String

    /// The localized question displayed to the customer.
    let prompt: String

    /// The kind of answer the question accepts.
    let answerType: AdditionalKYCAnswerType

    /// Whether the customer must answer the question before submitting.
    let required: Bool

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case prompt
        case answerType = "answer_type"
        case required
    }
}
