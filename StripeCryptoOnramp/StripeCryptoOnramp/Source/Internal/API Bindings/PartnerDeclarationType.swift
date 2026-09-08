//
//  PartnerDeclarationType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/1/26.
//

import Foundation

/// A type of partner declaration that can require customer acceptance.
enum PartnerDeclarationType: String, Codable {

    /// The partner's transaction terms.
    case transactionTerms = "transaction_terms"

    /// The partner's terms of service.
    case termsOfService = "terms_of_service"
}
