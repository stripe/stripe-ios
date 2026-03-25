//
//  Timeout.swift
//  StripeCore
//
//  Created by Joyce Qin on 10/28/25.
//

import Foundation

@_spi(STP) public struct TimeoutError: Error {}
@_spi(STP) public struct UnexpectedNilError: Error {}

/// Runs multiple operations in parallel with individual timeouts
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operations: Variadic operations to run with timeout
/// - Returns: Tuple of Results in the order that the operations were passed in, where each Result contains either the operation's value or its error
 @_spi(STP) public func withTimeout<each T>(
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

/// Runs a singular operation with a timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for the operation to complete
///   - operation: The operation to run with a timeout
/// - Returns: The operation's value
private func withTimeout<T>(
    _ timeout: TimeInterval,
    _ operation: @escaping () async throws -> T
) async throws -> T {
    let timeoutNs = UInt64(timeout) * 1_000_000_000

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
