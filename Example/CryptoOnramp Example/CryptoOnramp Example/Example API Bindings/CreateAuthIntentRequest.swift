//
//  CreateAuthIntentRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

struct CreateAuthIntentRequest: Encodable {
    let oauthScopes: [OAuthScopes]

    // MARK: - Encodable

    enum CodingKeys: CodingKey {
        case oauthScopes
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(oauthScopes.map(\.rawValue).joined(separator: ","), forKey: .oauthScopes)
    }
}
