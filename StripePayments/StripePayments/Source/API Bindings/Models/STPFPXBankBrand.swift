//
//  STPFPXBankBrand.swift
//  StripePayments
//
//  Created by David Estes on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// The various bank brands available for FPX payments.
@objc public enum STPFPXBankBrand: Int {
    /// Maybank2U
    case maybank2U
    /// CIMB Clicks
    case CIMB
    /// Public Bank
    case publicBank
    /// RHB Bank
    case RHB
    /// Hong Leong Bank
    case hongLeongBank
    /// AmBank
    case ambank
    /// Affin Bank
    case affinBank
    /// Alliance Bank
    case allianceBank
    /// Bank Islam
    case bankIslam
    /// Bank Muamalat
    case bankMuamalat
    /// Bank Rakyat
    case bankRakyat
    /// BSN
    case BSN
    /// HSBC BANK
    case HSBC
    /// KFH
    case KFH
    /// Maybank2E
    case maybank2E
    /// OCBC Bank
    case ocbc
    /// Standard Chartered
    case standardChartered
    /// UOB Bank
    case UOB
    /// An unknown bank
    case unknown
    /// Agrobank
    case agrobank
    /// Bank of China
    case bankOfChina
    /// MBSB Bank
    case mbsbBank
}

@_spi(STP) extension STPFPXBankBrand: CaseIterable {}

/// Convenience methods for using FPX bank brands.
public class STPFPXBank: NSObject {
    /// Returns a string representation for the provided bank brand;
    /// i.e. `STPFPXBank.stringFrom(brand:.uob) == "UOB Bank"`.
    /// - Parameter brand: The brand you want to convert to a string
    /// - Returns: A string representing the brand, suitable for displaying to a user.
    @objc public static func stringFrom(_ brand: STPFPXBankBrand) -> String? {
        return displayNames[brand]
    }

    /// Returns a bank brand provided a string representation identifying a bank brand;
    /// i.e. `STPFPXBankBrandFromIdentifier(@"uob") == STPCardBrandUob`.
    /// - Parameter identifier: The identifier for the brand
    /// - Returns: The STPFPXBankBrand enum value
    @objc public static func brandFrom(_ identifier: String?) -> STPFPXBankBrand {
        guard let brand = identifier?.lowercased() else {
            return .unknown
        }
        return brandsByIdentifier[brand] ?? .unknown
    }

    /// Returns a string representation identifying the provided bank brand;
    /// i.e. `STPIdentifierFromFPXBankBrand(STPCardBrandUob) ==  @"uob"`.
    /// - Parameter brand: The brand you want to convert to a string
    /// - Returns: A string representing the brand, suitable for using with the Stripe API.
    @objc public static func identifierFrom(_ brand: STPFPXBankBrand) -> String? {
        return identifiers[brand]
    }

    /// Human-readable display names, keyed by bank brand.
    private static let displayNames: [STPFPXBankBrand: String] = [
        .affinBank: "Affin Bank",
        .allianceBank: "Alliance Bank",
        .ambank: "AmBank",
        .bankIslam: "Bank Islam",
        .bankMuamalat: "Bank Muamalat",
        .bankRakyat: "Bank Rakyat",
        .BSN: "BSN",
        .CIMB: "CIMB Clicks",
        .hongLeongBank: "Hong Leong Bank",
        .HSBC: "HSBC BANK",
        .KFH: "KFH",
        .maybank2E: "Maybank2E",
        .maybank2U: "Maybank2U",
        .ocbc: "OCBC Bank",
        .publicBank: "Public Bank",
        .RHB: "RHB Bank",
        .standardChartered: "Standard Chartered",
        .UOB: "UOB Bank",
        .unknown: "Unknown",
        .agrobank: "Agrobank",
        .bankOfChina: "Bank of China",
        .mbsbBank: "MBSB Bank",
    ]

    /// API identifiers, keyed by bank brand.
    private static let identifiers: [STPFPXBankBrand: String] = [
        .affinBank: "affin_bank",
        .allianceBank: "alliance_bank",
        .ambank: "ambank",
        .bankIslam: "bank_islam",
        .bankMuamalat: "bank_muamalat",
        .bankRakyat: "bank_rakyat",
        .BSN: "bsn",
        .CIMB: "cimb",
        .hongLeongBank: "hong_leong_bank",
        .HSBC: "hsbc",
        .KFH: "kfh",
        .maybank2E: "maybank2e",
        .maybank2U: "maybank2u",
        .ocbc: "ocbc",
        .publicBank: "public_bank",
        .RHB: "rhb",
        .standardChartered: "standard_chartered",
        .UOB: "uob",
        .unknown: "unknown",
        .agrobank: "agrobank",
        .bankOfChina: "bank_of_china",
        .mbsbBank: "mbsb_bank",
    ]

    /// Bank brands keyed by the API identifier accepted by `brandFrom(_:)`.
    /// Mirrors `identifiers`, so every known brand round-trips through
    /// `identifierFrom(_:)` / `brandFrom(_:)`. `.unknown` is intentionally
    /// excluded so unrecognized identifiers fall through to `.unknown`.
    private static let brandsByIdentifier: [String: STPFPXBankBrand] = [
        "affin_bank": .affinBank,
        "alliance_bank": .allianceBank,
        "ambank": .ambank,
        "bank_islam": .bankIslam,
        "bank_muamalat": .bankMuamalat,
        "bank_rakyat": .bankRakyat,
        "bsn": .BSN,
        "cimb": .CIMB,
        "hong_leong_bank": .hongLeongBank,
        "hsbc": .HSBC,
        "kfh": .KFH,
        "maybank2e": .maybank2E,
        "maybank2u": .maybank2U,
        "ocbc": .ocbc,
        "public_bank": .publicBank,
        "rhb": .RHB,
        "standard_chartered": .standardChartered,
        "uob": .UOB,
        "agrobank": .agrobank,
        "bank_of_china": .bankOfChina,
        "mbsb_bank": .mbsbBank,
    ]
}
