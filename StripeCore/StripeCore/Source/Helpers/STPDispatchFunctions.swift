//
//  STPDispatchFunctions.swift
//  StripeCore
//
//  Created by Brian Dorfman on 10/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public func stpDispatchToMainThreadIfNecessary(_ block: @Sendable @escaping @MainActor () -> Void) {
    if Thread.isMainThread {
        Task { @MainActor in
            block()
        }
    } else {
        DispatchQueue.main.async(execute: block)
    }
}
