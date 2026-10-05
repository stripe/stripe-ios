//
//  AdditionalKYCQuestionnaireModel.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

import Combine
import Foundation

/// Collects answers to the questionnaire accompanying a document requirement.
@MainActor
final class AdditionalKYCQuestionnaireModel: ObservableObject {

    /// Maximum Unicode scalars in each answer, matching the backend's 5,000-character safeguard.
    private static let maximumAnswerLength = 5_000

    /// The questions to display, in the order supplied by the backend.
    let questions: [AdditionalKYCQuestionnaire.Question]

    /// Draft answers keyed by question identifier, preserved when navigating back to the questionnaire.
    @Published private(set) var answers: [String: String] = [:]

    /// Whether every required question has a nonblank answer.
    var canContinue: Bool {
        questions.allSatisfy { !$0.required || !answer(for: $0).isEmpty }
    }

    /// Answers to submit alongside the documents, omitting unanswered optional questions.
    var fulfillment: AdditionalKYCFulfillmentQuestionnaire {
        .init(answers: questions.compactMap { question in
            let value = answer(for: question)
            return value.isEmpty ? nil : .init(questionId: question.id, value: value)
        })
    }

    /// Creates answer state for a supported questionnaire.
    /// - Parameter questionnaire: The questions returned for either document collection flow.
    /// - Throws: `DocumentCollectionError.unsupportedRequirement` for unsupported answer types or invalid identifiers.
    init(questionnaire: AdditionalKYCQuestionnaire) throws {
        guard questionnaire.questions.allSatisfy({ $0.answerType == .freeText && !$0.id.isEmpty }),
              Set(questionnaire.questions.map(\.id)).count == questionnaire.questions.count else {
            throw DocumentCollectionError.unsupportedRequirement
        }
        questions = questionnaire.questions
    }

    /// Stores an answer up to the backend's 5,000-character limit.
    /// - Parameters:
    ///   - answer: The customer's answer.
    ///   - questionID: The identifier of the question being answered.
    func setAnswer(_ answer: String, for questionID: String) {
        answers[questionID] = String(answer.unicodeScalars.prefix(Self.maximumAnswerLength))
    }

    private func answer(for question: AdditionalKYCQuestionnaire.Question) -> String {
        (answers[question.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
