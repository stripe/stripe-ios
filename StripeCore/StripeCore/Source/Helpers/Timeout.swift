//
//  Timeout.swift
//  StripeCore
//
//  Created by Joyce Qin on 10/28/25.
//

import Foundation

@_spi(STP) public struct TimeoutError: Error {}
@_spi(STP) public struct UnexpectedNilError: Error {}

/// Runs an operation with a timeout.
/// Used as a fallback where Swift parameter packs are unavailable at runtime.
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operation: Operation to run with timeout
/// - Returns: A Result that contains either the operation's value or its error
@_spi(STP) @discardableResult public func withTimeout<T>(
    _ timeout: TimeInterval,
    _ operation: @escaping () async throws -> T
) async -> Result<T, Error> {
    let task = Task<T, Error> {
        return try await withTimeout(timeout) { try await operation() }
    }
    return await task.result
}

/// Runs two operations in parallel with individual timeouts.
/// Used as a fallback where Swift parameter packs are unavailable at runtime.
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operation1: First operation to run with timeout
///   - operation2: Second operation to run with timeout
/// - Returns: Tuple of Results in the order that the operations were passed in, where each Result contains either the operation's value or its error
@_spi(STP) @discardableResult public func withTimeout<T1, T2>(
    _ timeout: TimeInterval,
    _ operation1: @escaping () async throws -> T1,
    _ operation2: @escaping () async throws -> T2
) async -> (Result<T1, Error>, Result<T2, Error>) {
    let task1 = Task<T1, Error> {
        return try await withTimeout(timeout) { try await operation1() }
    }
    let task2 = Task<T2, Error> {
        return try await withTimeout(timeout) { try await operation2() }
    }
    return await (task1.result, task2.result)
}

/// Runs multiple operations in parallel with individual timeouts.
/// Requires iOS 17+ due to Swift parameter pack runtime support (_swift_allocateMetadataPack).
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operations: Variadic operations to run with timeout
/// - Returns: Tuple of Results in the order that the operations were passed in, where each Result contains either the operation's value or its error
///
/// - Important:
///     Cancellation does not propagate to unstructured Tasks e.g. created with `Task { }`.
///     If you need to cancel the inner task, you must explicitly call `.cancel()` on it.
///   - ✅ Structured tasks (e.g. calling async functions directly) are automatically canceled on timeout:
///     ```
///     withTimeout(5.0) {
///         await someAsyncFunction()  // This is canceled if timeout occurs (i.e. Task.isCancelled can be true inside the method)
///     }
///     ```
///   - ❌ Unstructured Tasks within operations are not automatically canceled:
///     ```
///     withTimeout(5.0) {
///         await Task {
///             await someAsyncFunction() // Inner Task is NOT canceled - Task.isCancelled is never true
///         }.value
///         // You must cancel the task yourself when `withTimeout` throws a `TimeoutError`
///     }
///     ```
#if compiler(>=5.9)
@available(iOS 17, *)
@_spi(STP) @discardableResult public func withTimeout<each T>(
    _ timeout: TimeInterval,
    _ operations: repeat @escaping () async throws -> each T
) async -> (repeat Result<each T, Error>) {
    // Wrap each operation with timeout logic
    let timeoutTasks = (repeat Task<each T, Error> {
        return try await withTimeout(timeout) { try await (each operations)() }
    })
    // Wait for all tasks to complete and collect results using .result
    return await (repeat (each timeoutTasks).result)
}
#endif

/// Runs a singular operation with a timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for the operation to complete
///   - operation: The operation to run with a timeout
/// - Returns: The operation's value
private func withTimeout<T>(
    _ timeout: TimeInterval,
    _ operation: @escaping () async throws -> T
) async throws -> T {
    let timeoutNs = UInt64(timeout * 1_000_000_000)

    // TaskGroups don't return until all of its child tasks have completed, so we use a continuation to escape hatch out of the TaskGroup with the winner of the race (value or TimeoutError)
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
        Task(priority: .high) {
            // Race the operation against a timeout
            await withThrowingTaskGroup(of: T.self) { group in
                // Add the task
                group.addTask {
                    return try await operation()
                }

                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: timeoutNs)
                    throw TimeoutError()
                }

                // Cancel remaining task
                defer {
                    group.cancelAll()
                }

                do {
                    // Get the winner
                    guard let result = try await group.next() else {
                        stpAssertionFailure("Result could not be unwrapped.")
                        throw UnexpectedNilError() // should never happen; only nil when group is empty
                    }
                    // Operation finished before the timeout
                    continuation.resume(returning: result)
                } catch {
                    // Operation timed out
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
