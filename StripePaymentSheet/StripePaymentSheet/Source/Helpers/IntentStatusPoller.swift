//
//  IntentStatusPoller.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Repeatedly retrieves a value and reports changes to its status.
///
/// This type is main-thread confined. Stripe API client completion blocks are delivered on the main
/// thread, and callers update UI in `didUpdate`.
final class IntentStatusPoller<Value, Status: Equatable> {
    typealias RetrieveValue = (@escaping (Value?) -> Void) -> Void

    private let retryInterval: TimeInterval
    private let retrieveValue: RetrieveValue
    private let statusKeyPath: KeyPath<Value, Status>
    private let didUpdate: (Value) -> Void

    private var lastStatus: Status?
    private var nextPollWorkItem: DispatchWorkItem?
    private var pollingGeneration = 0
    private var isPolling = false

    init(
        retryInterval: TimeInterval,
        retrieveValue: @escaping RetrieveValue,
        status: KeyPath<Value, Status>,
        didUpdate: @escaping (Value) -> Void
    ) {
        self.retryInterval = retryInterval
        self.retrieveValue = retrieveValue
        self.statusKeyPath = status
        self.didUpdate = didUpdate
    }

    /// Begins polling. Calling this while polling is already active has no effect.
    func beginPolling() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !isPolling else { return }

        isPolling = true
        pollingGeneration += 1
        fetchStatus(pollingGeneration: pollingGeneration)
    }

    /// Suspends polling and ignores any in-flight response from the current polling generation.
    func suspendPolling() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard isPolling else { return }

        isPolling = false
        pollingGeneration += 1
        nextPollWorkItem?.cancel()
        nextPollWorkItem = nil
    }

    /// Retrieves the status once, independently of continuous polling.
    func pollOnce(completion: @escaping (Status?) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        fetchStatus(completion: completion)
    }

    private func fetchStatus(
        pollingGeneration requestGeneration: Int? = nil,
        completion: ((Status?) -> Void)? = nil
    ) {
        retrieveValue { [weak self] value in
            dispatchPrecondition(condition: .onQueue(.main))
            guard let self else { return }

            let isCurrentPollingRequest = requestGeneration.map {
                $0 == self.pollingGeneration && self.isPolling
            }
            guard isCurrentPollingRequest ?? true else { return }

            let status = value.map { $0[keyPath: self.statusKeyPath] }
            completion?(status)

            if let value, let status, status != self.lastStatus {
                self.lastStatus = status
                self.didUpdate(value)
            }

            // Retrieval failures are transient. Keep polling until the caller suspends us or the deadline expires.
            if isCurrentPollingRequest == true, let requestGeneration {
                self.retryAfterInterval(pollingGeneration: requestGeneration)
            }
        }
    }

    private func retryAfterInterval(pollingGeneration: Int) {
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchStatus(pollingGeneration: pollingGeneration)
        }
        nextPollWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval, execute: workItem)
    }
}
