//
//  ComplianceIdentifierType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 5/4/26.
//

import Foundation

/// The type of compliance identifier required or submitted for regulatory compliance.
@_spi(CryptoOnrampAlpha)
public struct ComplianceIdentifierType: Codable, Equatable, ExpressibleByStringLiteral, Hashable, RawRepresentable {

    // MARK: - RawRepresentable

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    // MARK: - Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    // MARK: - Encodable

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

    /// Unified Civil Number (Единен граждански номер) - Bulgaria.
    static let bgUCN = Self(rawValue: "bg_ucn")

    /// Osobni identifikacijski broj (OIB) - Croatia.
    static let hrOIB = Self(rawValue: "hr_oib")

    /// Tax Identification Code (TIC) - Cyprus.
    static let cyTIC = Self(rawValue: "cy_tic")

    /// Rodné číslo - Czech Republic.
    static let czRC = Self(rawValue: "cz_rc")

    /// Personnummer (CPR) - Denmark.
    static let dkCPR = Self(rawValue: "dk_cpr")

    /// Isikukood (PIC) - Estonia.
    static let eeIK = Self(rawValue: "ee_ik")

    /// Número de Identificación Fiscal (NIF) - Spain.
    static let esNIF = Self(rawValue: "es_nif")

    /// Henkilötunnus (HETU) - Finland.
    static let fiHETU = Self(rawValue: "fi_hetu")

    /// Numéro fiscal de référence (SPI) - France.
    static let frSPI = Self(rawValue: "fr_spi")

    /// Social security number (NIR) - France.
    static let frNIR = Self(rawValue: "fr_nir")

    /// Tax Identification Number (Steuer-ID) - Germany.
    static let deSTN = Self(rawValue: "de_stn")

    /// Tax Identification Number (ΑΦΜ) - Greece.
    static let grAFM = Self(rawValue: "gr_afm")

    /// Adóazonosító - Hungary.
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

    /// Numéro d'Identification Personnelle (NIF) - Luxembourg.
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

    /// Número de Identificação Fiscal (NIF) - Portugal.
    static let ptNIF = Self(rawValue: "pt_nif")

    /// Codul Numeric Personal (CNP) - Romania.
    static let roCNP = Self(rawValue: "ro_cnp")

    /// Rodné číslo - Slovakia.
    static let skRC = Self(rawValue: "sk_rc")

    /// Personal Identification Number (EMŠO) - Slovenia.
    static let siPIN = Self(rawValue: "si_pin")

    /// Personnummer (PIN) - Sweden.
    static let sePIN = Self(rawValue: "se_pin")
}
