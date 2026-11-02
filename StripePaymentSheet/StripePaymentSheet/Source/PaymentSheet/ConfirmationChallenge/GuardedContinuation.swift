//
//  GuardedContinuation.swift
//  StripePaymentSheet
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// Like `withCheckedContinuation`, but a completion handler invoked more than once
/// is ignored (with a debug assertion) instead of trapping.
///
/// `@MainActor` because, unlike `withCheckedContinuation` itself, a plain nonisolated `async`
/// function does not inherit the caller's executor — calling `body` (which synchronously kicks
/// off work like `STPPaymentHandler.confirmPaymentIntent`) off the caller's actor would let that
/// work run on a different executor than the actor-isolated state it mutates. All current callers
/// are already on the main actor.
@MainActor
func withGuardedContinuation<T>(
    _ body: (@escaping (T) -> Void) -> Void
) async -> T {
    await withCheckedContinuation { continuation in
        let lock = NSLock()
        var resumed = false
        body { value in
            lock.lock()
            defer { lock.unlock() }
            guard !resumed else {
                stpAssertionFailure("Completion handler invoked more than once")
                return
            }
            resumed = true
            continuation.resume(returning: value)
        }
    }
}
