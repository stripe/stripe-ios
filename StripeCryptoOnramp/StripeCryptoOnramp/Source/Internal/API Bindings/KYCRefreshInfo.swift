//
//  KYCRefreshInfo.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/27/25.
//

import Foundation

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
