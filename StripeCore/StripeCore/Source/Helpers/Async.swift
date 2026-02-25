//
//  Async.swift
//  StripeCore
//
//  Created by Yuki Tokuhiro on 9/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
// Native async/await wrapper for compatibility with existing codebase
// Migrated from Promise/Future pattern to use Swift's built-in async/await

import Foundation

// ⛔️ DEPRECATED: Futures are not fully thread safe and can cause crashes. Use Swift concurrency instead. ⛔️
@_spi(STP) public class Future<Value> {
    public typealias Result = Swift.Result<Value, Error>

    private let task: Task<Value, Error>

    public init(_ operation: @escaping () async throws -> Value) {
        self.task = Task {
            try await operation()
        }
    }

    internal init(task: Task<Value, Error>) {
        self.task = task
    }

    public func observe(
        on queue: DispatchQueue = .main,
        using callback: @escaping (Result) -> Void
    ) {
        Task {
            let result = await task.result
            queue.async {
                callback(result)
            }
        }
    }

    public func chained<T>(
        on queue: DispatchQueue = .main,
        using closure: @escaping (Value) throws -> Future<T>
    ) -> Future<T> {
        return Future<T> {
            let value = try await self.task.value
            let future = try closure(value)
            return try await future.task.value
        }
    }

    public func transformed<T>(
        on queue: DispatchQueue = .main,
        with closure: @escaping (Value) throws -> T
    ) -> Future<T> {
        return Future<T> {
            let value = try await self.task.value
            return try closure(value)
        }
    }
}

// ⛔️ DEPRECATED: Promises are not fully thread safe and can cause crashes. Use Swift concurrency instead. ⛔️
@_spi(STP) public class Promise<Value>: Future<Value> {
    private let continuation: CheckedContinuation<Value, Error>

    public init() {
        let (task, continuation) = Self.makeTask()
        self.continuation = continuation
        super.init(task: task)
    }

    public convenience init(value: Value) {
        self.init()
        resolve(with: value)
    }

    public convenience init(error: Error) {
        self.init()
        reject(with: error)
    }

    public func resolve(with value: Value) {
        continuation.resume(returning: value)
    }

    public func reject(with error: Error) {
        continuation.resume(throwing: error)
    }

    public func fullfill(with result: Result) {
        switch result {
        case .success(let value):
            resolve(with: value)
        case .failure(let error):
            reject(with: error)
        }
    }

    public func fulfill(with block: () throws -> Value) {
        do {
            let value = try block()
            resolve(with: value)
        } catch {
            reject(with: error)
        }
    }

    private static func makeTask() -> (Task<Value, Error>, CheckedContinuation<Value, Error>) {
        var continuation: CheckedContinuation<Value, Error>!
        let task = Task<Value, Error> {
            try await withCheckedThrowingContinuation { cont in
                continuation = cont
            }
        }
        return (task, continuation)
    }
}
