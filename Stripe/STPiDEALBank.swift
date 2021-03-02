//
//  STPiDEALBank.swift
//  StripeiOS
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
    case moneyou
    case rabobank
    case regiobank
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
            return STPLocalizedString(
                "ABN Amro", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .asnBank:
            return STPLocalizedString(
                "ASN Bank", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .bunq:
            return STPLocalizedString(
                "bunq B.V.", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .handelsbanken:
            return STPLocalizedString(
                "Handelsbanken", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .ing:
            return STPLocalizedString(
                "ING Bank", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .knab:
            return STPLocalizedString(
                "Knab", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .moneyou:
            return STPLocalizedString(
                "Moneyou", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .rabobank:
            return STPLocalizedString(
                "Rabobank", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .regiobank:
            return STPLocalizedString(
                "RegioBank", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .snsBank:
            return STPLocalizedString(
                "SNS Bank", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .triodosBank:
            return STPLocalizedString(
                "Triodos Bank", "Bank brand name displayed inside iDEAL-bank selection picker")
        case .vanLanschot:
            return STPLocalizedString(
                "Van Lanschot", "Bank brand name displayed inside iDEAL-bank selection picker")
        }
    }
}
