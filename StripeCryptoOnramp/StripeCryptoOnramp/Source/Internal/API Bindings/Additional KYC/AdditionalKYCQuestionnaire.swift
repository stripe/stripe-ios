//
//  AdditionalKYCQuestionnaire.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A questionnaire used to collect information for an additional KYC requirement.
struct AdditionalKYCQuestionnaire: Codable, Equatable {

    /// The questions to present to the customer.
    let questions: [AdditionalKYCQuestion]
}
