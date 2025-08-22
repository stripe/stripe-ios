//
//  AuthenticatedUserRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct AuthenticateUserRequest: Encodable {
    let email: String
    let oauthScopes: String

    enum CodingKeys: String, CodingKey {
        case email
        case oauthScopes = "oauth_scopes"
    }

    init(email: String, oauthScopes: [String] = OAuthScopes.inlineScope) {
        self.email = email
        self.oauthScopes = oauthScopes.joined(separator: ",")
    }
}

private enum OAuthScopes: String, CaseIterable {
    static let inlineScope: [String] = [OAuthScopes.userinfoRead.rawValue]
    static let allScopes: [String] = Self.allCases.map(\.rawValue)

    case userinfoRead = "userinfo:read"
    case userinfoAddressesRead = "userinfo.addresses:read"
    case kycStatusRead = "kyc.status:read"
    case kycWrite = "kyc:write"
    case kycRead = "kyc:read"
    case kycShare = "kyc:share"
    case authPersistLoginRead = "auth.persist_login:read"
    case paymentMethodsRead = "payment_methods:read"
    case paymentMethodsBankAccountsRead = "payment_methods.bank_accounts:read"
    case readEmail = "read_email"
    case readPhone = "read_phone"
    case shareFullName = "share_full_name"
    case shareEmail = "share_email"
    case shareAddress = "share_address"
}
