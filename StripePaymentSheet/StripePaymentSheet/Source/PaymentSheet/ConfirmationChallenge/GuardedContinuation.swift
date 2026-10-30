//
//  GuardedContinuation.swift
//  StripePaymentSheet
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// Like `withCheckedContinuation`, but a completion handler invoked more than once
/// is ignored (with a debug assertion) instead of trapping.
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
