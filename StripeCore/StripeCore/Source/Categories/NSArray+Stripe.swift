//
//  NSArray+Stripe.swift
//  StripeCore
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public extension Array {
    func stp_boundSafeObject(at index: Int) -> Element? {
        if index + 1 > count || index < 0 {
            return nil
        }
        return self[index]
    }
}
