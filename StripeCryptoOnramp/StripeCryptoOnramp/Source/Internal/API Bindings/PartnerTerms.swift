//
//  PartnerTerms.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/27/26.
//

import Foundation

/// The partner declaration state returned by `/v1/crypto/internal/partner_terms`.
enum PartnerTerms: Decodable, Equatable {

    /// A partner declaration that requires customer acceptance.
    struct Declaration: Decodable, Equatable {

        /// The declaration's unique identifier.
        let id: String

        /// The type of declaration requiring acceptance.
        let type: PartnerDeclarationType

        /// The localized declaration HTML to display.
        let html: String

        // MARK: - Decodable

        private enum CodingKeys: String, CodingKey {
            case id
            case type
            case html = "text"
        }
    }

    /// The customer must accept the declaration before continuing.
    /// - Parameters:
    ///   - partner: The partner whose declaration requires acceptance.
    ///   - declaration: The declaration to present and record acceptance for.
    case required(partner: String, declaration: Declaration)

    /// The customer has already accepted the current declaration or isn't required to accept it.
    case notRequired

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case required
        case partner
        case declaration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if try container.decode(Bool.self, forKey: .required) {
            self = try .required(
                partner: container.decode(String.self, forKey: .partner),
                declaration: container.decode(Declaration.self, forKey: .declaration)
            )
        } else {
            self = .notRequired
        }
    }
}
