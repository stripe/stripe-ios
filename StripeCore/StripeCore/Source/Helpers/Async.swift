//
//  Async.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 9/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
// Futures and Promises. Delete this when the SDK is iOS13+ and use the Combine framework instead.
//
// Taken from https://github.com/JohnSundell/SwiftBySundell/blob/master/Blog/Under-the-hood-of-Futures-and-Promises.swift
//
// MIT License
//
// Copyright (c) 2017 John Sundell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

@_spi(STP) public class Future<Value> {
    public typealias Result = Swift.Result<Value, Error>

    fileprivate var result: Result? {
        // Observe whenever a result is assigned, and report it:
        didSet {
            propertyAccessQueue.async { [self] in
                result.map(report)
            }
        }
    }
    private var callbacks = [(Result) -> Void]()
    // Since our methods can be called on different threads and our methods access our properties, we need to protect access to prevent race conditions.
    let propertyAccessQueue = DispatchQueue(label: "FutureQueue", qos: .userInitiated)

    public func observe(
        on queue: DispatchQueue = .main,
        using callback: @escaping (Result) -> Void
    ) {
        let wrappedCallback: (Result) -> Void = { r in
            queue.async {
                callback(r)
            }
        }

        propertyAccessQueue.async { [self] in
            // If a result has already been set, call the callback directly:
            if let result {
                return wrappedCallback(result)
            }

            callbacks.append(wrappedCallback)
        }
    }

    private func report(result: Result) {
        propertyAccessQueue.async { [self] in
            callbacks.forEach { $0(result) }
            callbacks = []
        }
    }

    public func chained<T>(
        on queue: DispatchQueue = .main,
        using closure: @escaping (Value) throws -> Future<T>
    ) -> Future<T> {
        // We'll start by constructing a "wrapper" promise that will be
        // returned from this method:
        let promise = Promise<T>()

        // Observe the current future:
        observe(on: queue) { result in
            switch result {
            case .success(let value):
                do {
                    // Attempt to construct a new future using the value
                    // returned from the first one:
                    let future = try closure(value)

                    // Observe the "nested" future, and once it
                    // completes, resolve/reject the "wrapper" future:
                    future.observe(on: queue) { result in
                        switch result {
                        case .success(let value):
                            promise.resolve(with: value)
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .failure(let error):
                promise.reject(with: error)
            }
        }

        return promise
    }

    public func transformed<T>(
        on queue: DispatchQueue = .main,
        with closure: @escaping (Value) throws -> T
    ) -> Future<T> {
        chained(on: queue) { value in
             try Promise(value: closure(value))
        }
    }
}

@_spi(STP) public class Promise<Value>: Future<Value> {
    public override init() {
        super.init()
    }

    public convenience init(
        value: Value
    ) {
        self.init()

        // If the value was already known at the time the promise
        // was constructed, we can report it directly:
        result = .success(value)
    }

    public convenience init(
        error: Error
    ) {
        self.init()
        result = .failure(error)
    }

    public func resolve(with value: Value) {
        result = .success(value)
    }

    public func reject(with error: Error) {
        result = .failure(error)
    }

    public func fullfill(with result: Result) {
        self.result = result
    }

    public func fulfill(with block: () throws -> Value) {
        do {
            self.result = .success(try block())
        } catch {
            self.result = .failure(error)
        }
    }
}
