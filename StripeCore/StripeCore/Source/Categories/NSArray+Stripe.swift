//
//  NSArray+Stripe.swift
//  StripeCore
//
//  Created by Jack Flintermann on 1/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) extension Array {
    public func stp_boundSafeObject(at index: Int) -> Element? {
        if index + 1 > count || index < 0 {
            return nil
        }
        return self[index]
    }
}

extension Array where Element == String {
    public func caseInsensitiveContains(_ other: String) -> Bool {
        return self.map { $0.uppercased() }.contains(other.uppercased())
    }
}

extension Array where Element: Equatable {
    @discardableResult public mutating func remove(_ element: Element) -> Element? {
        guard let index = firstIndex(of: element) else { return nil }
        return remove(at: index)
    }
}
