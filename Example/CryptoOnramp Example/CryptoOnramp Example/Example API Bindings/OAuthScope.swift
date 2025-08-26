//
//  OAuthScope.swift
//  CryptoOnramp Example
//
//  Created by Mat Schmid on 8/23/25.
//

import Foundation

enum OAuthScopes: String, CaseIterable {
    static let onrampScope: [OAuthScopes] = [OAuthScopes.cryptoRamp]
    static let allScopes: [OAuthScopes] = Self.allCases

    case cryptoRamp = "crypto:ramp"
    case userinfoRead = "userinfo:read"
    case userinfoAddressesRead = "userinfo.addresses:read"
    case kycStatusRead = "kyc.status:read"
    case kycWrite = "kyc:write"
    case kycRead = "kyc:read"
    case kycShare = "kyc:share"
    case authPersistLoginRead = "auth.persist_login:read"
    case paymentMethodsRead = "payment_methods:read"
    case paymentMethodsBankAccountsRead = "payment_methods.bank_accounts:read"
}
