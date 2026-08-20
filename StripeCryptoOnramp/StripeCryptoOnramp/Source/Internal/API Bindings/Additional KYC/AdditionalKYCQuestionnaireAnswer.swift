//
//  AdditionalKYCQuestionnaireAnswer.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// An answer submitted for one additional KYC question.
struct AdditionalKYCQuestionnaireAnswer: Codable, Equatable {

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
