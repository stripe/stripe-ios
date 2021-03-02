//
//  NSArray+Stripe.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

//
//  NSArray+Stripe_BoundSafe.m
//  Stripe
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension Array {
    func stp_boundSafeObject(at index: Int) -> Any? {
        if index + 1 > count || index < 0 {
            return nil
        }
        return self[index]
    }

    func stp_arrayByRemovingNulls() -> [AnyHashable] {
        var result: [AnyHashable] = []

        for obj in self {
            switch obj {
            case let obj as Array:
                // Save array after removing any null values
                result.append(obj.stp_arrayByRemovingNulls())
            case let obj as NSDictionary:
                // Save dictionary after removing any null values
                let dict = obj.stp_dictionaryByRemovingNulls() as NSDictionary
                result.append(dict)
            case let obj as AnyHashable:
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
