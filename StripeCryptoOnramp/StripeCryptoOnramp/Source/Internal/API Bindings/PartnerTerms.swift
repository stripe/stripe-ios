//
//  PartnerTerms.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// The partner declaration state returned by `/v1/crypto/internal/partner_terms`.
enum PartnerTerms: Decodable, Equatable {

    /// The customer must accept the declaration before continuing.
    /// - Parameters:
    ///   - partner: The partner whose declaration requires acceptance.
    ///   - version: The version of the declaration requiring acceptance.
    ///   - declarationId: The unique identifier of the declaration requiring acceptance.
    ///   - html: The localized declaration HTML to display.
    case required(partner: String, version: String, declarationId: String, html: String)

    /// The customer has already accepted the current declaration or isn't required to accept it.
    case notRequired

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case required
        case partner
        case version
        case declarationId = "declaration_id"
        case html = "text"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if try container.decode(Bool.self, forKey: .required) {
            self = try .required(
                partner: container.decode(String.self, forKey: .partner),
                version: container.decode(String.self, forKey: .version),
                declarationId: container.decode(String.self, forKey: .declarationId),
                html: container.decode(String.self, forKey: .html)
            )
        } else {
            self = .notRequired
        }
    }
}
