//
//  AdditionalKYCSubmissionType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// The kind of information used to fulfill an additional KYC requirement.
enum AdditionalKYCSubmissionType: Codable, Equatable {

    /// One or more uploaded documents.
    case document

    /// Answers to a collection of questions.
    case questionnaire

    /// A submission type value that this SDK version does not recognize.
    case unknown(String)

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "document":
            self = .document
        case "questionnaire":
            self = .questionnaire
        case let value:
            self = .unknown(value)
        }
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .document:
            try container.encode("document")
        case .questionnaire:
            try container.encode("questionnaire")
        case .unknown(let value):
            try container.encode(value)
        }
    }
}
