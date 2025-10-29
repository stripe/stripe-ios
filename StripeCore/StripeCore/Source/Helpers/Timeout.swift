//
//  Timeout.swift
//  StripeCore
//
//  Created by Joyce Qin on 10/28/25.
//

import Foundation

/// Represents an asynchronous operation with a cancellation handler
@_spi(STP) public struct AsyncOperation<T> {
    public let run: () async throws -> T
    public let cancel: () async -> Void

    public init(operation: @escaping () async throws -> T, onCancel: @escaping () async -> Void) {
        self.run = operation
        self.cancel = onCancel
    }
}

enum TimeoutError: Error {
    case timeout
}


/// Runs multiple asynchronous operations in parallel with individual timeouts
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operations: Variadic async operations with their cancellation handlers
/// - Returns: Tuple of Results, where each Result contains either the operation's value or its error
@_spi(STP) public func withTimeout<each T>(
    timeout: TimeInterval,
    _ operations: repeat AsyncOperation<each T>
) async -> (repeat Result<(each T)?, Error>) {
    // Start all operations in parallel using runWithTimeout
    let tasks = (repeat Task<(each T)?, Error> {
        return try await withTimeout(timeout: timeout, each operations)
    })

    // Wait for all tasks to complete and collect results using .result
    return await (repeat (each tasks).result)
}

/// Runs an asynchronous operation with a timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for the operation to complete
///   - operation: The asynchronous operation with a cancellation handler
/// - Returns: Optional result from operation (nil if timed out or failed)
func withTimeout<T>(
    timeout: TimeInterval,
    _ operation: AsyncOperation<T>
) async throws -> T? {
    let timeoutNs = UInt64(timeout) * 1_000_000_000

    return try await withThrowingTaskGroup(of: T.self) { group in
        // Add operation task
        group.addTask {
            return try await operation.run()
        }

        // Add timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: timeoutNs)
            throw TimeoutError.timeout
        }

        defer {
            Task {
                await operation.cancel()
            }
            group.cancelAll()
        }

        // Return first result (either operation result or timeout)
        return try await group.next()
    }
}
