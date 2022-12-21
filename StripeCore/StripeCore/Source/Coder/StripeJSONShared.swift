//
//  StripeJSONShared.swift
//  StripeCore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

// Constants
internal let STPMaintainExistingCase = CodingUserInfoKey(rawValue: "_STPMaintainExistingCase")!

internal struct STPCodingKey: CodingKey {
    init?(
        stringValue: String
    ) {
        self.stringValue = stringValue
    }

    init?(
        intValue: Int
    ) {
        self.intValue = intValue
        self.stringValue = intValue.description
    }

    init(
        stringValue: String,
        intValue: Int?
    ) {
        self.intValue = intValue
        self.stringValue = stringValue
    }

    var stringValue: String
    var intValue: Int?
}
