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
    /// Agrobank
    case agrobank
    /// Alliance Bank
    case allianceBank
    /// Bank Islam
    case bankIslam
    /// Bank Muamalat
    case bankMuamalat
    /// Bank Rakyat
    case bankRakyat
    /// Bank of China
    case bankOfChina
    /// BSN
    case BSN
    /// Deutsche Bank
    case deutscheBank
    /// HSBC BANK
    case HSBC
    /// KFH
    case KFH
    /// Maybank2E
    case maybank2E
    /// OCBC Bank
    case ocbc
    /// Public Bank Enterprise
    case publicBankEnterprise
    /// Standard Chartered
    case standardChartered
    /// UOB Bank
    case UOB
    /// MBSB Bank
    case mbsb_bank
    /// BNP Paribas
    case bnp_paribas
    /// Citibank
    case citibank
    /// An unknown bank
    case unknown
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

    /// Returns the code identifying the provided bank brand in the FPX status API;
    /// i.e. `STPIdentifierFromFPXBankBrand(STPCardBrandUob) ==  @"UOB0226"`.
    /// - Parameters:
    ///   - brand: The brand you want to convert to an FPX bank code
    ///   - isBusiness: Requests the code for the business version of this bank brand, which may be different from the code used for individual accounts
    /// - Returns: A string representing the brand, suitable for checking against the FPX status API.
    @objc public static func bankCodeFrom(_ brand: STPFPXBankBrand, _ isBusiness: Bool) -> String? {
        guard let codes = bankCodes[brand] else {
            return nil
        }
        return isBusiness ? codes.business : codes.individual
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
        .deutscheBank: "Deutsche Bank",
        .publicBankEnterprise: "Public Bank Enterprise",
        .mbsb_bank: "MBSB Bank",
        .bnp_paribas: "BNP Paribas",
        .citibank: "Citibank",
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
        .agrobank: "agrobank",
        .bankOfChina: "bank_of_china",
        .deutscheBank: "deutsche_bank",
        .publicBankEnterprise: "pb_enterprise",
        .mbsb_bank: "mbsb_bank",
        .bnp_paribas: "bnp_paribas",
        .citibank: "citibank",
        .unknown: "unknown",
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
        "deutsche_bank": .deutscheBank,
        "pb_enterprise": .publicBankEnterprise,
        "mbsb_bank": .mbsb_bank,
        "bnp_paribas": .bnp_paribas,
        "citibank": .citibank,
    ]

    /// FPX status API bank codes, keyed by bank brand. A `nil` code means that
    /// variant (business or individual) is unavailable for the brand.
    private static let bankCodes: [STPFPXBankBrand: (business: String?, individual: String?)] = [
        .affinBank: (business: "ABB0232", individual: "ABB0233"),
        .allianceBank: (business: "ABMB0213", individual: "ABMB0212"),
        .ambank: (business: "AMBB0208", individual: "AMBB0209"),
        .bankIslam: (business: nil, individual: "BIMB0340"),
        .bankMuamalat: (business: "BMMB0342", individual: "BMMB0341"),
        .bankRakyat: (business: "BKRM0602", individual: "BKRM0602"),
        .BSN: (business: nil, individual: "BSN0601"),
        .CIMB: (business: "BCBB0235", individual: "BCBB0235"),
        .hongLeongBank: (business: "HLB0224", individual: "HLB0224"),
        .HSBC: (business: "HSBC0223", individual: "HSBC0223"),
        .KFH: (business: "KFH0346", individual: "KFH0346"),
        .maybank2E: (business: "MBB0228", individual: "MBB0228"),
        .maybank2U: (business: nil, individual: "MB2U0227"),
        .ocbc: (business: "OCBC0229", individual: "OCBC0229"),
        .publicBank: (business: "PBB0233", individual: "PBB0233"),
        .RHB: (business: "RHB0218", individual: "RHB0218"),
        .standardChartered: (business: "SCB0215", individual: "SCB0216"),
        .UOB: (business: "UOB0228", individual: "UOB0226"),
        .agrobank: (business: "AGRO01", individual: "AGRO02"),
        .bankOfChina: (business: nil, individual: "BOCM01"),
        .deutscheBank: (business: "DBB0199", individual: nil),
        .publicBankEnterprise: (business: "PBB0234", individual: nil),
        .mbsb_bank: (business: "MBSB001", individual: "MBSB001"),
        .bnp_paribas: (business: "BNP003", individual: nil),
        .citibank: (business: "CITI0218", individual: nil),
        .unknown: (business: "unknown", individual: "unknown"),
    ]

}
