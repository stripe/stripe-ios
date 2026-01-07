//
//  STPPromise.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public class STPPromise<T>: NSObject {
    @_spi(STP) public typealias STPPromiseErrorBlock = (Error) -> Void

    @_spi(STP) public typealias STPPromiseValueBlock = (T) -> Void

    @_spi(STP) public var completed: Bool {
        return error != nil || value != nil
    }
    private(set) var value: T?
    private(set) var error: Error?

    private var successCallbacks: [STPPromiseValueBlock] = []
    private var errorCallbacks: [STPPromiseErrorBlock] = []

    convenience init(
        error: Error
    ) {
        self.init()
        self.fail(error)
    }

    convenience init(
        value: T
    ) {
        self.init()
        self.succeed(value)
    }
    @_spi(STP) public func succeed(_ value: T) {
        if completed {
            return
        }
        self.value = value
        stpDispatchToMainThreadIfNecessary({
            for valueBlock in self.successCallbacks {
                valueBlock(value)
            }
            self.successCallbacks = []
            self.errorCallbacks = []
        })
    }

    @_spi(STP) public func fail(_ error: Error) {
        if completed {
            return
        }
        self.error = error
        stpDispatchToMainThreadIfNecessary({
            for errorBlock in self.errorCallbacks {
                errorBlock(error)
            }
            self.successCallbacks = []
            self.errorCallbacks = []
        })
    }

    @discardableResult @_spi(STP) public func onSuccess(_ callback: @escaping STPPromiseValueBlock) -> Self {
        if let value = value {
            stpDispatchToMainThreadIfNecessary({
                callback(value)
            })
        } else {
            successCallbacks = successCallbacks + [callback]
        }
        return self
    }

    @discardableResult @_spi(STP) public func onFailure(_ callback: @escaping STPPromiseErrorBlock) -> Self {
        if let error = error {
            stpDispatchToMainThreadIfNecessary({
                callback(error)
            })
        } else {
            errorCallbacks = errorCallbacks + [callback]
        }
        return self
    }
}
