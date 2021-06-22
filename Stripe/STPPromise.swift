//
//  STPPromise.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

class STPPromise<T>: NSObject {
    typealias STPPromiseErrorBlock = (Error) -> Void

    typealias STPPromiseValueBlock = (T) -> Void

    typealias STPPromiseCompletionBlock = (T?, Error?) -> Void

    typealias STPPromiseMapBlock = (T) -> Any?

    typealias STPPromiseFlatMapBlock = (T) -> STPPromise

    var completed: Bool {
        return error != nil || value != nil
    }
    private(set) var value: T?
    private(set) var error: Error?

    private var successCallbacks: [STPPromiseValueBlock] = []
    private var errorCallbacks: [STPPromiseErrorBlock] = []

    convenience init(error: Error) {
        self.init()
        self.fail(error)
    }

    convenience init(value: T) {
        self.init()
        self.succeed(value)
    }
    func succeed(_ value: T) {
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

    func fail(_ error: Error) {
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

    func complete(with promise: STPPromise) {
        weak var weakSelf = self
        promise.onSuccess({ value in
            let strongSelf = weakSelf
            strongSelf?.succeed(value)
        }).onFailure({ error in
            let strongSelf = weakSelf
            strongSelf?.fail(error)
        })
    }

    @discardableResult func onSuccess(_ callback: @escaping STPPromiseValueBlock) -> Self {
        if let value = value {
            stpDispatchToMainThreadIfNecessary({
                callback(value)
            })
        } else {
            successCallbacks = successCallbacks + [callback]
        }
        return self
    }

    @discardableResult func onFailure(_ callback: @escaping STPPromiseErrorBlock) -> Self {
        if let error = error {
            stpDispatchToMainThreadIfNecessary({
                callback(error)
            })
        } else {
            errorCallbacks = errorCallbacks + [callback]
        }
        return self
    }

    @discardableResult func onCompletion(_ callback: @escaping STPPromiseCompletionBlock) -> Self {
        return onSuccess({ value in
            callback(value, nil)
        }).onFailure({ error in
            callback(nil, error)
        })
    }

    @discardableResult func map(_ callback: @escaping STPPromiseMapBlock) -> STPPromise {
        let wrapper = STPPromise.init()
        onSuccess({ value in
            wrapper.succeed(callback(value) as! T)
        }).onFailure({ error in
            wrapper.fail(error)
        })
        return wrapper
    }

    @discardableResult func flatMap(_ callback: @escaping STPPromiseFlatMapBlock) -> STPPromise {
        let wrapper = STPPromise.init()
        onSuccess({ value in
            let `internal` = callback(value)
            `internal`.onSuccess({ internalValue in
                wrapper.succeed(internalValue)
            }).onFailure({ internalError in
                wrapper.fail(internalError)
            })
        }).onFailure({ error in
            wrapper.fail(error)
        })
        return wrapper
    }
}
