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

    /// The questions to display, in the order supplied by the backend.
    let questions: [AdditionalKYCQuestionnaire.Question]

    /// Draft answers keyed by question identifier, preserved when navigating back to the questionnaire.
    @Published var answers: [String: String] = [:]

    /// Whether every answer fits its limit and every required question has a nonblank answer.
    var canContinue: Bool {
        questions.allSatisfy { question in
            (!question.required || !answer(for: question).isEmpty)
                && (answers[question.id] ?? "").unicodeScalars.count <= question.maxQuestionnaireAnswerCharacters
        }
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
    /// - Throws: `DocumentCollectionError.unsupportedRequirement` for unsupported answer types, invalid identifiers, or invalid answer limits.
    init(questionnaire: AdditionalKYCQuestionnaire) throws {
        guard questionnaire.questions.allSatisfy({ $0.answerType == .freeText && !$0.id.isEmpty && $0.maxQuestionnaireAnswerCharacters > 0 }),
              Set(questionnaire.questions.map(\.id)).count == questionnaire.questions.count else {
            throw DocumentCollectionError.unsupportedRequirement
        }
        questions = questionnaire.questions
    }

    private func answer(for question: AdditionalKYCQuestionnaire.Question) -> String {
        (answers[question.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
