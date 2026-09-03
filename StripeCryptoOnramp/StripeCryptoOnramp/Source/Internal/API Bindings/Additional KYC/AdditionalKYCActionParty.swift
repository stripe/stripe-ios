//
//  AdditionalKYCActionParty.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// A party that may be responsible for the next action on an additional KYC requirement.
enum AdditionalKYCActionParty: Decodable, Equatable {

    /// The customer must provide additional information.
    case user

    /// The liquidity partner must review or process the submitted information.
    case partner

    /// Stripe must review or process the submitted information.
    case stripe

    /// An action party value that this SDK version does not recognize.
    case unknown(String)

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
}
