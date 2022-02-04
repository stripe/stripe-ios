//
//  MLMultiArray+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/26/22.
//

import Foundation
import CoreML

extension MLMultiArray {
    subscript(key: [Int]) -> NSNumber {
        return self[key.map { NSNumber(value: $0) }]
    }
}
