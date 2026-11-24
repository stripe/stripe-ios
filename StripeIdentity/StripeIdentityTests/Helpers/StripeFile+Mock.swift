//
//  StripeFile+Mock.swift
//  StripeIdentityTests
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

extension StripeFile {
    static func mock(id: String) throws -> StripeFile {
        let data = Data("""
        {
          "created": 0,
          "id": "\(id)",
          "purpose": "identity_private",
          "size": 1,
          "type": "jpg"
        }
        """.utf8)
        return try JSONDecoder().decode(StripeFile.self, from: data)
    }
}
