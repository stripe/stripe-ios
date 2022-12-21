//
//  OperationDebouncer.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Provides a mechanism for debouncing operations.
///
/// You can think of `OperationDebouncer` as a serial queue that can only hold a single operation
/// to be performed after a brief delay ("debounce time"). Rapidly enqueuing operations at an interval
/// less than the debounce time will result in only the last operation eventually being executed, given that
/// no additional operations are enqueued within debounce time.
final class OperationDebouncer {

    private let dispatchQueue: DispatchQueue
    private let debounceTime: DispatchTimeInterval

    private var pendingWorkItem: DispatchWorkItem?

    /// Creates a new OperationDebouncer object.
    /// - Parameters:
    ///   - debounceTime: Time to wait before executing the enqueued operation.
    ///   - dispatchQueue: The target queue on which to execute blocks.
    init(debounceTime: DispatchTimeInterval, dispatchQueue: DispatchQueue = .main) {
        self.debounceTime = debounceTime
        self.dispatchQueue = dispatchQueue
    }

    deinit {
        cancel()
    }

    /// Enqueues an operation block by first canceling any pending block that was previously enqueued.
    ///
    /// If no additional calls are made to this method for a period of time defined by `debounceTime`,
    /// the last enqueued block will be invoked.
    ///
    /// - Parameter block: Block to be eventually executed.
    func enqueue(block: @escaping () -> Void) {
        // Cancel any pending item
        cancel()

        let workItem = DispatchWorkItem(block: { [weak self] in
            self?.pendingWorkItem = nil
            block()
        })

        pendingWorkItem = workItem

        dispatchQueue.asyncAfter(deadline: .now() + debounceTime, execute: workItem)
    }

    /// Cancels any pending operation.
    func cancel() {
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
    }

}
