//
//  PartnerDeclarationType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/1/26.
//

import Foundation

/// A type of partner declaration that can require customer acceptance.
enum PartnerDeclarationType: String, Encodable {

    /// The partner's terms and conditions.
    case termsAndConditions = "terms"

    /// The partner's terms of service.
    case termsOfService = "tos"
}
