//
//  Timeout.swift
//  StripeCore
//
//  Created by Joyce Qin on 10/28/25.
//

import Foundation

@_spi(STP) public struct TimeoutError: Error {}

// MARK: - Timeout with TaskGroup and CheckedContinuation escape hatch
/// Runs multiple operations in parallel with individual timeouts
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operations: Variadic operations to run with timeout
/// - Returns: Tuple of Results, where each Result contains either the task's value or its error
 @_spi(STP) public func withTimeout<each T>(
    _ timeout: TimeInterval,
    _ operations: repeat @escaping () async throws -> each T
 ) async -> (repeat Result<(each T)?, Error>) {
    // Wrap each operation with timeout logic
    let timeoutTasks = (repeat Task<(each T)?, Error> {
        return try await withTimeout(timeout) { try await (each operations)() }
    })

    // Wait for all tasks to complete and collect results using .result
    return await (repeat (each timeoutTasks).result)
 }

/// Runs a singular operation with a timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for the operation to complete
///   - operation: The operation to run with a timeout
/// - Returns: A Task whose result contains either the operation's value or its error
private func withTimeout<T>(
    _ timeout: TimeInterval,
    _ operation: @escaping () async throws -> T
) async throws -> T? {
    let timeoutNs = UInt64(timeout) * 1_000_000_000

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T?, Error>) in
        Task {
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

                defer {
                    group.cancelAll()
                }

                do {
                    let result = try await group.next()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
