//
//  StringCodingKey.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/6/24.
//

import Foundation

struct StringCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}
