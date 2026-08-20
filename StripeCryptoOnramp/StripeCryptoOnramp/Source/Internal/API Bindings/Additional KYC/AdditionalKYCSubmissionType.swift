//
//  AdditionalKYCSubmissionType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// The kind of information used to fulfill an additional KYC requirement.
enum AdditionalKYCSubmissionType: Equatable, Codable {

    /// One or more uploaded documents.
    case document

    /// Answers to a collection of questions.
    case questionnaire

    /// A submission type value that this SDK version does not recognize.
    case unknown(String)

    /// The raw API value for the submission type.
    var rawValue: String {
        switch self {
        case .document:
            return "document"
        case .questionnaire:
            return "questionnaire"
        case .unknown(let value):
            return value
        }
    }

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
        try container.encode(rawValue)
    }
}
