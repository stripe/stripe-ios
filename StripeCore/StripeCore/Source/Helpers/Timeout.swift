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

/// Runs an asynchronous operation with a timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for the operation to complete
///   - operation: The asynchronous operation with a cancellation handler
/// - Returns: Optional result from operation (nil if timed out or failed)
@_spi(STP) public func runWithTimeout<T>(
    timeout: TimeInterval,
    _ operation: AsyncOperation<T>
) async throws -> T? {
    let timeoutNs = UInt64(timeout) * 1_000_000_000

    return try await withThrowingTaskGroup(of: T?.self) { group in
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
        return try await group.next()?.flatMap { $0 }
    }
}

/// Runs multiple asynchronous operations in parallel with individual timeouts
/// - Parameters:
///   - timeout: The maximum time interval to wait for each operation to complete
///   - operations: Variadic async operations with their cancellation handlers
/// - Returns: Tuple of Results, where each Result contains either the operation's value or its error
@_spi(STP) public func withResultTimeout<each T>(
    timeout: TimeInterval,
    _ operations: repeat AsyncOperation<each T>
) async -> (repeat Result<each T, Error>) {
    // Start all operations in parallel using runWithTimeout
    let tasks = (repeat Task<each T, Error> {
        if let value = try await runWithTimeout(timeout: timeout, (each operations)) {
            return value
        } else {
            // runWithTimeout returned nil, meaning timeout occurred
            throw TimeoutError.timeout
        }
    })

    // Wait for all tasks to complete and collect results using .result
    return await (repeat (each tasks).result)
}

/// Runs multiple asynchronous operations in parallel with a shared timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for operations to complete
///   - operations: Variadic async operations with their cancellation handlers
/// - Returns: Tuple of optional results from operations (nil if timed out or failed)
@_spi(STP) public func withTimeout<each T>(
    timeout: TimeInterval,
    _ operations: repeat AsyncOperation<each T>
) async -> (repeat (each T)?) {
    let timeoutNs = UInt64(timeout) * 1_000_000_000

    // Start all operations as unstructured tasks
    let tasks = (repeat Task { try? await (each operations).run() })

    // Race timeout against all operations completing
    await withTaskGroup(of: Void.self) { group in
        // Wait-for-all task
        group.addTask {
            // Wait for all operations to complete
            await (repeat _ = (each tasks).value)
        }
        // Timeout task
        group.addTask {
            try? await Task.sleep(nanoseconds: timeoutNs)
        }
        defer {
            // ⚠️ TaskGroups can't return until all child tasks have completed, so we need to cancel remaining tasks and handle cancellation to complete as quickly as possible
            Task {
                repeat (each tasks).cancel()
                await (repeat (each operations).cancel())
            }
            group.cancelAll()
        }
        // Wait for either all operations to complete or timeout
        await group.next()
    }

    // Collect results (completed operations have values, cancelled/incomplete ones are nil)
    return await (repeat (each tasks).value)
}
