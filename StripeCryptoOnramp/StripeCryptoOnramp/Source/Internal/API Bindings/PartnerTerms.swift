//
//  PartnerTerms.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// The terms and conditions state returned by `/v1/crypto/internal/partner_terms`.
enum PartnerTerms: Decodable, Equatable {

    /// The customer must accept the terms and conditions before continuing.
    /// - Parameters:
    ///   - partner: The partner whose terms and conditions require acceptance.
    ///   - version: The version of the terms and conditions requiring acceptance.
    ///   - html: The localized terms and conditions HTML to display.
    case required(partner: String, version: String, html: String)

    /// The customer has already accepted the current terms and conditions.
    case notRequired

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case required
        case partner
        case version
        case html = "text"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if try container.decode(Bool.self, forKey: .required) {
            self = try .required(
                partner: container.decode(String.self, forKey: .partner),
                version: container.decode(String.self, forKey: .version),
                html: container.decode(String.self, forKey: .html)
            )
        } else {
            self = .notRequired
        }
    }
}
