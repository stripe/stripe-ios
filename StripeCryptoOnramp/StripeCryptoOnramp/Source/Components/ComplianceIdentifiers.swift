//
//  ComplianceIdentifiers.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 4/30/26.
//

import Foundation

/// The type of compliance identifier required or submitted for regulatory compliance.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierType: Codable, Equatable, ExpressibleByStringLiteral, Hashable, RawRepresentable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public extension ComplianceIdentifierType {

    /// Steuernummer - Austria.
    static let atSTN = Self(rawValue: "at_stn")

    /// National Registration Number (NRN) - Belgium.
    static let beNRN = Self(rawValue: "be_nrn")

    /// Unified Civil Number - Bulgaria.
    static let bgUCN = Self(rawValue: "bg_ucn")

    /// Osobni identifikacijski broj (OIB) - Croatia.
    static let hrOIB = Self(rawValue: "hr_oib")

    /// Tax Identification Code (TIC) - Cyprus.
    static let cyTIC = Self(rawValue: "cy_tic")

    /// Rodne cislo - Czech Republic.
    static let czRC = Self(rawValue: "cz_rc")

    /// Personnummer (CPR) - Denmark.
    static let dkCPR = Self(rawValue: "dk_cpr")

    /// Isikukood (PIC) - Estonia.
    static let eeIK = Self(rawValue: "ee_ik")

    /// Henkilotunnus (HETU) - Finland.
    static let fiHETU = Self(rawValue: "fi_hetu")

    /// Numero fiscal de reference (SPI) - France.
    static let frSPI = Self(rawValue: "fr_spi")

    /// Tax Identification Number (Steuer-ID) - Germany.
    static let deSTN = Self(rawValue: "de_stn")

    /// Tax Identification Number (AFM) - Greece.
    static let grAFM = Self(rawValue: "gr_afm")

    /// Adoazonosito - Hungary.
    static let huAD = Self(rawValue: "hu_ad")

    /// Kennitala - Iceland.
    static let isKT = Self(rawValue: "is_kt")

    /// Personal Public Service Number (PPSN) - Ireland.
    static let iePPSN = Self(rawValue: "ie_ppsn")

    /// Codice fiscale - Italy.
    static let itCF = Self(rawValue: "it_cf")

    /// Personas kods - Latvia.
    static let lvPK = Self(rawValue: "lv_pk")

    /// Asmens kodas - Lithuania.
    static let ltAK = Self(rawValue: "lt_ak")

    /// Numero d'Identification Personnelle (NIF) - Luxembourg.
    static let luNIF = Self(rawValue: "lu_nif")

    /// National Identity Card Number - Malta.
    static let mtNIC = Self(rawValue: "mt_nic")

    /// Passport Number - Malta.
    static let mtPP = Self(rawValue: "mt_pp")

    /// Citizen Service Number (BSN) - Netherlands.
    static let nlBSN = Self(rawValue: "nl_bsn")

    /// PESEL number - Poland.
    static let plPESEL = Self(rawValue: "pl_pesel")

    /// Numer Identyfikacji Podatkowej (NIP) - Poland.
    static let plNIP = Self(rawValue: "pl_nip")

    /// Numero de Identificacao Fiscal (NIF) - Portugal.
    static let ptNIF = Self(rawValue: "pt_nif")

    /// Codul Numeric Personal (CNP) - Romania.
    static let roCNP = Self(rawValue: "ro_cnp")

    /// Rodne cislo - Slovakia.
    static let skRC = Self(rawValue: "sk_rc")

    /// Personal Identification Number - Slovenia.
    static let siPIN = Self(rawValue: "si_pin")

    /// Personnummer (PIN) - Sweden.
    static let sePIN = Self(rawValue: "se_pin")
}

/// The regulation requiring a compliance identifier.
@_spi(CryptoOnrampAlpha)
public struct ComplianceRegulation: Codable, Equatable, ExpressibleByStringLiteral, Hashable, RawRepresentable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public extension ComplianceRegulation {

    /// Common Reporting Standard (CRS) and Crypto-Asset Reporting Framework (CARF).
    static let euCARF = Self(rawValue: "eu_carf")

    /// Markets in Crypto-Assets Regulation (MICA).
    static let euMICA = Self(rawValue: "eu_mica")
}

/// A compliance identifier collected for MICA or CRS/CARF compliance.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifier: Codable, Equatable, Hashable {

    /// The type of identifier provided.
    public let type: ComplianceIdentifierType

    /// The identifier value.
    public let value: String

    /// Creates a `ComplianceIdentifier`.
    /// - Parameters:
    ///   - type: The type of identifier provided.
    ///   - value: The identifier value.
    public init(type: ComplianceIdentifierType, value: String) {
        self.type = type
        self.value = value
    }
}

/// A compliance identifier the customer still needs to provide.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierRequirement: Decodable, Equatable, Hashable {

    /// The type of identifier required.
    public let type: ComplianceIdentifierType

    /// The regulation requiring this identifier.
    public let regulation: ComplianceRegulation

    /// Creates a `ComplianceIdentifierRequirement`.
    /// - Parameters:
    ///   - type: The type of identifier required.
    ///   - regulation: The regulation requiring this identifier.
    public init(type: ComplianceIdentifierType, regulation: ComplianceRegulation) {
        self.type = type
        self.regulation = regulation
    }
}

/// A group describing alternative identifier types that may satisfy a requirement.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierAlternativeGroup: Decodable, Equatable, Hashable {

    /// The original identifier types required.
    public let originalMissingIdentifiers: [ComplianceIdentifierType]

    /// Alternative identifier types that may satisfy the original requirement.
    public let alternativeMissingIdentifiers: [ComplianceIdentifierType]

    /// Creates a `ComplianceIdentifierAlternativeGroup`.
    /// - Parameters:
    ///   - originalMissingIdentifiers: The original identifier types required.
    ///   - alternativeMissingIdentifiers: Alternative identifier types that may satisfy the original requirement.
    public init(
        originalMissingIdentifiers: [ComplianceIdentifierType],
        alternativeMissingIdentifiers: [ComplianceIdentifierType]
    ) {
        self.originalMissingIdentifiers = originalMissingIdentifiers
        self.alternativeMissingIdentifiers = alternativeMissingIdentifiers
    }

    private enum CodingKeys: String, CodingKey {
        case originalMissingIdentifiers = "original_missing_identifiers"
        case alternativeMissingIdentifiers = "alternative_missing_identifiers"
    }
}
