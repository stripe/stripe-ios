//
//  AdditionalKYCAnswerType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// The kind of answer accepted by an additional KYC question.
enum AdditionalKYCAnswerType: Equatable, Codable {

    /// A free-form text answer.
    case freeText

    /// An answer type value that this SDK version does not recognize.
    case unknown(String)

    /// The raw API value for the answer type.
    var rawValue: String {
        switch self {
        case .freeText:
            return "free_text"
        case .unknown(let value):
            return value
        }
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "free_text":
            self = .freeText
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
