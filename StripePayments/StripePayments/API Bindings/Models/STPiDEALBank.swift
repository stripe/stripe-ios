//
//  STPiDEALBank.swift
//  StripePayments
//
//  Created by Mel Ludowise on 2/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

enum STPiDEALBank: String, CaseIterable {
    case abnAmro = "abn_amro"
    case asnBank = "asn_bank"
    case bunq
    case handelsbanken
    case ing
    case knab
    case rabobank
    case regiobank
    case revolut
    case snsBank = "sns_bank"
    case triodosBank = "triodos_bank"
    case vanLanschot = "van_lanschot"

    /// The name of the bank as expected by Stripe's API.
    var name: String {
        return rawValue
    }

    /// The human-readable display name of the bank.
    var displayName: String {
        switch self {
        case .abnAmro:
            return "ABN Amro"
        case .asnBank:
            return "ASN Bank"
        case .bunq:
            return "bunq B.V."
        case .handelsbanken:
            return "Handelsbanken"
        case .ing:
            return "ING Bank"
        case .knab:
            return "Knab"
        case .rabobank:
            return "Rabobank"
        case .regiobank:
            return "RegioBank"
        case .revolut:
            return "Revolut"
        case .snsBank:
            return "SNS Bank"
        case .triodosBank:
            return "Triodos Bank"
        case .vanLanschot:
            return "Van Lanschot"
        }
    }
}
