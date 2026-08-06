//
//  ComplianceIdentifierType+DisplayName.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 5/4/26.
//

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

extension ComplianceIdentifierType {

    /// A human-readable display name for known identifier types.
    var displayName: String {
        switch self {
        case .atSTN:
            return "Steuernummer - Austria"
        case .beNRN:
            return "National Registration Number (NRN) - Belgium"
        case .bgUCN:
            return "Unified Civil Number (Единен граждански номер) - Bulgaria"
        case .hrOIB:
            return "Osobni identifikacijski broj (OIB) - Croatia"
        case .cyTIC:
            return "Tax Identification Code (TIC) - Cyprus"
        case .czRC:
            return "Rodné číslo - Czech Republic"
        case .dkCPR:
            return "Personnummer (CPR) - Denmark"
        case .eeIK:
            return "Isikukood (PIC) - Estonia"
        case .esNIF:
            return "Número de Identificación Fiscal (NIF) - Spain"
        case .fiHETU:
            return "Henkilötunnus (HETU) - Finland"
        case .frSPI:
            return "Numéro fiscal de référence (SPI) - France"
        case .frNIR:
            return "Numéro de sécurité sociale (NIR) - France"
        case .deSTN:
            return "Tax Identification Number (Steuer-ID) - Germany"
        case .grAFM:
            return "Tax Identification Number (ΑΦΜ) - Greece"
        case .huAD:
            return "Adóazonosító - Hungary"
        case .isKT:
            return "Kennitala - Iceland"
        case .iePPSN:
            return "Personal Public Service Number (PPSN) - Ireland"
        case .itCF:
            return "Codice fiscale - Italy"
        case .lvPK:
            return "Personas kods - Latvia"
        case .ltAK:
            return "Asmens kodas - Lithuania"
        case .luNIF:
            return "Numéro d'Identification Personnelle (NIF) - Luxembourg"
        case .mtNIC:
            return "National Identity Card Number - Malta"
        case .mtPP:
            return "Passport Number - Malta"
        case .nlBSN:
            return "Citizen Service Number (BSN) - Netherlands"
        case .plPESEL:
            return "PESEL number - Poland"
        case .plNIP:
            return "Numer Identyfikacji Podatkowej (NIP) - Poland"
        case .ptNIF:
            return "Número de Identificação Fiscal (NIF) - Portugal"
        case .roCNP:
            return "Codul Numeric Personal (CNP) - Romania"
        case .skRC:
            return "Rodné číslo - Slovakia"
        case .siPIN:
            return "Personal Identification Number (EMŠO) - Slovenia"
        case .sePIN:
            return "Personnummer (PIN) - Sweden"
        default:
            return rawValue
        }
    }

    var carfDisplayName: String {
        switch self {
        case .atSTN:
            return "Austria — at_stn"
        case .beNRN:
            return "Belgium — be_nrn"
        case .bgUCN:
            return "Bulgaria — bg_ucn"
        case .cyTIC:
            return "Cyprus — cy_tic"
        case .czRC:
            return "Czech Republic — cz_rc"
        case .deSTN:
            return "Germany — de_stn"
        case .dkCPR:
            return "Denmark — dk_cpr"
        case .eeIK:
            return "Estonia — ee_ik"
        case .esNIF:
            return "Spain — es_nif"
        case .fiHETU:
            return "Finland — fi_hetu"
        case .frNIR:
            return "France — fr_nir (NIR)"
        case .frSPI:
            return "France — fr_spi (SPI)"
        case .grAFM:
            return "Greece — gr_afm"
        case .hrOIB:
            return "Croatia — hr_oib"
        case .huAD:
            return "Hungary — hu_ad"
        case .iePPSN:
            return "Ireland — ie_ppsn"
        case .itCF:
            return "Italy — it_cf"
        case .ltAK:
            return "Lithuania — lt_ak"
        case .luNIF:
            return "Luxembourg — lu_nif"
        case .lvPK:
            return "Latvia — lv_pk"
        case .mtNIC:
            return "Malta — mt_nic"
        case .nlBSN:
            return "Netherlands — nl_bsn"
        case .plPESEL:
            return "Poland — pl_pesel"
        case .ptNIF:
            return "Portugal — pt_nif"
        case .roCNP:
            return "Romania — ro_cnp"
        case .sePIN:
            return "Sweden — se_pin"
        case .siPIN:
            return "Slovenia — si_pin"
        case .skRC:
            return "Slovakia — sk_rc"
        default:
            return rawValue
        }
    }
}
