//
//  Optional+StripeCore.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 7/17/25.
//

import Foundation

@_spi(STP) public extension Optional {
    var isNil: Bool {
        return self == nil
    }
}
