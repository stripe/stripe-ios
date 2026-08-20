//
//  AdditionalKYCActionParty.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A party that may be responsible for the next action on an additional KYC requirement.
enum AdditionalKYCActionParty: Equatable, Codable {

    /// The customer must provide additional information.
    case user

    /// The liquidity partner must review or process the submitted information.
    case partner

    /// Stripe must review or process the submitted information.
    case stripe

    /// An action party value that this SDK version does not recognize.
    case unknown(String)

    /// The raw API value for the action party.
    var rawValue: String {
        switch self {
        case .user:
            return "user"
        case .partner:
            return "partner"
        case .stripe:
            return "stripe"
        case .unknown(let value):
            return value
        }
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        switch try decoder.singleValueContainer().decode(String.self) {
        case "user":
            self = .user
        case "partner":
            self = .partner
        case "stripe":
            self = .stripe
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
