//
//  AdditionalKYCAnswerType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// The kind of answer accepted by an additional KYC question.
enum AdditionalKYCAnswerType: Decodable, Equatable {

    /// A free-form text answer.
    case freeText

    /// An answer type value that this SDK version does not recognize.
    case unknown(String)

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "free_text":
            self = .freeText
        case let value:
            self = .unknown(value)
        }
    }
}
