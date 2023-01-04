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
}

/// Convenience methods for using FPX bank brands.
public class STPFPXBank: NSObject {
    /// Returns a string representation for the provided bank brand;
    /// i.e. `STPFPXBank.stringFrom(brand:.uob) == "UOB Bank"`.
    /// - Parameter brand: The brand you want to convert to a string
    /// - Returns: A string representing the brand, suitable for displaying to a user.
    @objc public static func stringFrom(_ brand: STPFPXBankBrand) -> String? {
        switch brand {
        case .affinBank:
            return "Affin Bank"
        case .allianceBank:
            return "Alliance Bank"
        case .ambank:
            return "AmBank"
        case .bankIslam:
            return "Bank Islam"
        case .bankMuamalat:
            return "Bank Muamalat"
        case .bankRakyat:
            return "Bank Rakyat"
        case .BSN:
            return "BSN"
        case .CIMB:
            return "CIMB Clicks"
        case .hongLeongBank:
            return "Hong Leong Bank"
        case .HSBC:
            return "HSBC BANK"
        case .KFH:
            return "KFH"
        case .maybank2E:
            return "Maybank2E"
        case .maybank2U:
            return "Maybank2U"
        case .ocbc:
            return "OCBC Bank"
        case .publicBank:
            return "Public Bank"
        case .RHB:
            return "RHB Bank"
        case .standardChartered:
            return "Standard Chartered"
        case .UOB:
            return "UOB Bank"
        case .unknown:
            return "Unknown"
        }
    }

    /// Returns a bank brand provided a string representation identifying a bank brand;
    /// i.e. `STPFPXBankBrandFromIdentifier(@"uob") == STPCardBrandUob`.
    /// - Parameter identifier: The identifier for the brand
    /// - Returns: The STPFPXBankBrand enum value
    @objc public static func brandFrom(_ identifier: String?) -> STPFPXBankBrand {
        let brand = identifier?.lowercased()
        if brand == "affin_bank" {
            return .affinBank
        }
        if brand == "alliance_bank" {
            return .allianceBank
        }
        if brand == "ambank" {
            return .ambank
        }
        if brand == "bank_islam" {
            return .bankIslam
        }
        if brand == "bank_muamalat" {
            return .bankMuamalat
        }
        if brand == "bank_rakyat" {
            return .bankRakyat
        }
        if brand == "bsn" {
            return .BSN
        }
        if brand == "cimb" {
            return .CIMB
        }
        if brand == "hong_leong_bank" {
            return .hongLeongBank
        }
        if brand == "hsbc" {
            return .HSBC
        }
        if brand == "kfh" {
            return .KFH
        }
        if brand == "maybank2e" {
            return .maybank2E
        }
        if brand == "maybank2u" {
            return .maybank2U
        }
        if brand == "ocbc" {
            return .ocbc
        }
        if brand == "public_bank" {
            return .publicBank
        }
        if brand == "rhb" {
            return .RHB
        }
        if brand == "standard_chartered" {
            return .standardChartered
        }
        if brand == "uob" {
            return .UOB
        }
        return .unknown
    }

    /// Returns a string representation identifying the provided bank brand;
    /// i.e. `STPIdentifierFromFPXBankBrand(STPCardBrandUob) ==  @"uob"`.
    /// - Parameter brand: The brand you want to convert to a string
    /// - Returns: A string representing the brand, suitable for using with the Stripe API.
    @objc public static func identifierFrom(_ brand: STPFPXBankBrand) -> String? {
        switch brand {
        case .affinBank:
            return "affin_bank"
        case .allianceBank:
            return "alliance_bank"
        case .ambank:
            return "ambank"
        case .bankIslam:
            return "bank_islam"
        case .bankMuamalat:
            return "bank_muamalat"
        case .bankRakyat:
            return "bank_rakyat"
        case .BSN:
            return "bsn"
        case .CIMB:
            return "cimb"
        case .hongLeongBank:
            return "hong_leong_bank"
        case .HSBC:
            return "hsbc"
        case .KFH:
            return "kfh"
        case .maybank2E:
            return "maybank2e"
        case .maybank2U:
            return "maybank2u"
        case .ocbc:
            return "ocbc"
        case .publicBank:
            return "public_bank"
        case .RHB:
            return "rhb"
        case .standardChartered:
            return "standard_chartered"
        case .UOB:
            return "uob"
        case .unknown:
            return "unknown"
        }
    }

    /// Returns the code identifying the provided bank brand in the FPX status API;
    /// i.e. `STPIdentifierFromFPXBankBrand(STPCardBrandUob) ==  @"UOB0226"`.
    /// - Parameters:
    ///   - brand: The brand you want to convert to an FPX bank code
    ///   - isBusiness: Requests the code for the business version of this bank brand, which may be different from the code used for individual accounts
    /// - Returns: A string representing the brand, suitable for checking against the FPX status API.
    @objc public static func bankCodeFrom(_ brand: STPFPXBankBrand, _ isBusiness: Bool) -> String? {
        switch brand {
        case .affinBank:
            if isBusiness {
                return "ABB0232"
            } else {
                return "ABB0233"
            }
        case .allianceBank:
            if isBusiness {
                return "ABMB0213"
            } else {
                return "ABMB0212"
            }
        case .ambank:
            if isBusiness {
                return "AMBB0208"
            } else {
                return "AMBB0209"
            }
        case .bankIslam:
            if isBusiness {
                return nil
            } else {
                return "BIMB0340"
            }
        case .bankMuamalat:
            if isBusiness {
                return "BMMB0342"
            } else {
                return "BMMB0341"
            }
        case .bankRakyat:
            if isBusiness {
                return "BKRM0602"
            } else {
                return "BKRM0602"
            }
        case .BSN:
            if isBusiness {
                return nil
            } else {
                return "BSN0601"
            }
        case .CIMB:
            if isBusiness {
                return "BCBB0235"
            } else {
                return "BCBB0235"
            }
        case .hongLeongBank:
            if isBusiness {
                return "HLB0224"
            } else {
                return "HLB0224"
            }
        case .HSBC:
            if isBusiness {
                return "HSBC0223"
            } else {
                return "HSBC0223"
            }
        case .KFH:
            if isBusiness {
                return "KFH0346"
            } else {
                return "KFH0346"
            }
        case .maybank2E:
            if isBusiness {
                return "MBB0228"
            } else {
                return "MBB0228"
            }
        case .maybank2U:
            if isBusiness {
                return nil
            } else {
                return "MB2U0227"
            }
        case .ocbc:
            if isBusiness {
                return "OCBC0229"
            } else {
                return "OCBC0229"
            }
        case .publicBank:
            if isBusiness {
                return "PBB0233"
            } else {
                return "PBB0233"
            }
        case .RHB:
            if isBusiness {
                return "RHB0218"
            } else {
                return "RHB0218"
            }
        case .standardChartered:
            if isBusiness {
                return "SCB0215"
            } else {
                return "SCB0216"
            }
        case .UOB:
            if isBusiness {
                return "UOB0228"
            } else {
                return "UOB0226"
            }
        case .unknown:
            return "unknown"
        }
    }

}
