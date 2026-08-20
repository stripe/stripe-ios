//
//  AdditionalKYCAdditionalRequirements.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Information that must be collected in addition to the primary KYC submission.
struct AdditionalKYCAdditionalRequirements: Codable, Equatable {

    /// A questionnaire that must be completed with the primary submission.
    let questionnaire: AdditionalKYCQuestionnaire?
}
