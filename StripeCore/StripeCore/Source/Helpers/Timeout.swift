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
        return try await withTimeout(timeout){ try await (each operations)() }
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
            try await withThrowingTaskGroup(of: T.self) { group in
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

                continuation.resume(returning: try await group.next())
            }
        }
    }
 }

// MARK: - Timeout with TaskWithCancellation
/// Represents a running task with an associated cancellation handler
/// ⚠️ Swift concurrency uses cooperative cancellation, so each task is responsible for responding to cancellation and exiting early
@_spi(STP) public struct TaskWithCancellation<T> {
    public let task: Task<T, Error>

    /// Convenience initializer that creates a task with a cancellation handler
    public init(
        operation: @escaping @Sendable () async throws -> T,
        onCancel: @escaping @Sendable () -> Void
    ) {
        self.task = Task {
            try await withTaskCancellationHandler {
                try await operation()
            } onCancel: {
                onCancel()
            }
        }
    }

}

/// Runs multiple tasks in parallel with individual timeouts
/// - Parameters:
///   - timeout: The maximum time interval to wait for each task to complete
///   - tasks: Variadic tasks with their cancellation handlers
/// - Returns: Tuple of Results, where each Result contains either the task's value or its error
@_spi(STP) public func withTimeout<each T>(
    timeout: TimeInterval,
    _ tasks: repeat TaskWithCancellation<each T>
) async -> (repeat Result<(each T)?, Error>) {
    // Wrap each task with timeout logic
    let timeoutTasks = (repeat Task<(each T)?, Error> {
        return try await withTimeout(timeout: timeout, each tasks)
    })

    // Wait for all tasks to complete and collect results using .result
    return await (repeat (each timeoutTasks).result)
}

/// Runs a task with a timeout
/// - Parameters:
///   - timeout: The maximum time interval to wait for the task to complete
///   - taskWithCancellation: The task with its cancellation handler
/// - Returns: Optional result from task (nil if timed out or failed)
private func withTimeout<T>(
    timeout: TimeInterval,
    _ taskWithCancellation: TaskWithCancellation<T>
) async throws -> T? {
    let timeoutNs = UInt64(timeout) * 1_000_000_000

    return try await withThrowingTaskGroup(of: T.self) { group in
        // Add the task
        group.addTask {
            return try await taskWithCancellation.task.value
        }

        // Add timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: timeoutNs)
            throw TimeoutError()
        }

        defer {
            // ⚠️ TaskGroups can't return until all child tasks have completed, so we need to cancel the task and run its cancellation handler
            taskWithCancellation.task.cancel()
            group.cancelAll()
        }

        // Return first result (either task result or timeout)
        return try await group.next()
    }
}
