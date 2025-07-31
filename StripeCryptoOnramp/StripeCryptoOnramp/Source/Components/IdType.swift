//
//  IdType.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/30/25.
//

import Foundation

/// Represents possible types of customer identification.
@_spi(CryptoOnrampSDKPreview)
public enum IdType: String, Codable, CaseIterable {
    case aadhaar = "aadhaar"
    case abn = "abn"
    case businessTaxDeductionAccountNumber = "business_tax_deduction_account_number"
    case companyRegistrationNumber = "company_registration_number"
    case corporateIdentityNumber = "corporate_identity_number"
    case goodsAndServicesTaxIdNumber = "goods_and_services_tax_id_number"
    case indiaImporterExporterCode = "india_importer_exporter_code"
    case exportLicenseId = "export_license_id"
    case legacyIdNumber = "id_number"
    case limitedLiabilityPartnershipId = "limited_liability_partnership_id"
    case pan = "pan"
    case udyamNumber = "udyam_number"
    case taxId = "tax_id"
    case vatId = "vat_id"
    case voterId = "voter_id"
    case brazilCpf = "brazil_cpf"
    case brazilRegistroGeral = "brazil_registro_geral"
    case spanishPersonNumber = "spanish_person_number"
    case thLaserCode = "th_laser_code"
    case fiscalCode = "fiscal_code"
    case socialSecurityNumber = "social_security_number"
    case regonNumber = "regon_number"
    case passportNumber = "passport_number"
    case drivingLicenseNumber = "driving_license_number"
    case photoIdNumber = "photo_id_number"
}
