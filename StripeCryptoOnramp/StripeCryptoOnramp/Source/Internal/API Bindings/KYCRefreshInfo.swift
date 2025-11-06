//
//  KYCRefreshInfo.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/27/25.
//

import Foundation
@_spi(STP) import StripePaymentSheet

/// KYC information common to the KYC-refresh-related APIs:
/// - /v1/crypto/internal/kyc_data_retrieve
/// - /v1/crypto/internal/refresh_consumer_person
struct KYCRefreshInfo {

    /// The user’s first name.
    let firstName: String

    /// The user’s last name.
    let lastName: String?

    /// The user’s birth date.
    let dateOfBirth: KycInfo.DateOfBirth

    /// The user’s address.
    var address: Address

    /// The last four digits of the user’s id number.
    let idNumberLast4: String?

    /// The type of the id number.
    let idType: IdType?
}

extension KYCRefreshInfo: VerifyKYCInfo {
    var dateOfBirthDay: Int { dateOfBirth.day }
    var dateOfBirthMonth: Int { dateOfBirth.month }
    var dateOfBirthYear: Int { dateOfBirth.year }
    var line1: String? { address.line1 }
    var line2: String? { address.line2 }
    var city: String? { address.city }
    var state: String? { address.state }
    var postalCode: String? { address.postalCode }
    var country: String? { address.country }
}
