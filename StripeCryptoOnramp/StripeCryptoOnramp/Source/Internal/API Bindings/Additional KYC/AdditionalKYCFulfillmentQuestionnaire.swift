//
//  AdditionalKYCFulfillmentQuestionnaire.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Questionnaire answers submitted for an additional KYC requirement.
struct AdditionalKYCFulfillmentQuestionnaire: Codable, Equatable {

    /// The customer's answers to the questionnaire.
    let answers: [AdditionalKYCQuestionnaireAnswer]

}
