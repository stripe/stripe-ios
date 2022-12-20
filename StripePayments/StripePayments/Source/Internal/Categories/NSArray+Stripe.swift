//
//  NSArray+Stripe.swift
//  StripePayments
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension Array {
    func stp_arrayByRemovingNulls() -> [Any] {
        var result: [Any] = []

        for obj in self {
            switch obj {
            case let obj as Array:
                // Save array after removing any null values
                result.append(obj.stp_arrayByRemovingNulls())
            case let obj as [AnyHashable: Any]:
                // Save dictionary after removing any null values
                let dict = obj.stp_dictionaryByRemovingNulls()
                result.append(dict)
            case let obj as Any:
                if obj is NSNull {
                    // Skip null value
                    continue
                }
                // Save other value
                result.append(obj)
            default:
                continue
            }
        }

        return result
    }
}
