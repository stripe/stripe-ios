//
//  MLMultiArray+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CoreML
import Foundation

extension MLMultiArray {
    subscript(key: [Int]) -> NSNumber {
        return self[key.map { NSNumber(value: $0) }]
    }
}
