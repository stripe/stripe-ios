//
//  IntentStatusPoller.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCore
import StripePayments

protocol IntentStatusPollerDelegate: AnyObject {
    func didUpdate(paymentIntent: STPPaymentIntent)
}

protocol PaymentIntentRetrievable {
    func retrievePaymentIntent(withClientSecret clientSecret: String, completion: @escaping STPPaymentIntentCompletionBlock)
}

extension STPAPIClient: PaymentIntentRetrievable {}

class IntentStatusPoller {
    let retryInterval: TimeInterval
    let intentRetriever: PaymentIntentRetrievable
    let clientSecret: String

    private var lastStatus: STPPaymentIntentStatus = .unknown
    private let pollingQueue = DispatchQueue(label: "com.stripe.intent.status.queue")
    private var nextPollWorkItem: DispatchWorkItem?

    weak var delegate: IntentStatusPollerDelegate?

    private var isPolling: Bool = false {
        didSet {
            // Start polling if we weren't already polling
            if !oldValue && isPolling {
                fetchStatus()
            } else if !isPolling {
                nextPollWorkItem?.cancel()
            }
        }
    }

    init(retryInterval: TimeInterval, intentRetriever: PaymentIntentRetrievable, clientSecret: String) {
        self.retryInterval = retryInterval
        self.intentRetriever = intentRetriever
        self.clientSecret = clientSecret
    }

    // MARK: Public APIs

    /// Begins continuously polling at a frequency defined by `retryInterval`. The delegate will be
    /// notified of any status changes to the intent during this poll period.
    public func beginPolling() {
        isPolling = true
    }

    /// Suspends the ongoing polling process. After suspending, the delegate will not receive any status
    /// updates on the intent until polling is resumed using `beginPolling()`.
    public func suspendPolling() {
        isPolling = false
    }

    /// Triggers a single poll operation to fetch the intent status right away, regardless of the
    /// retryInterval. Whether or not continuous polling in ongoing, `pollOnce()` immediately updates the
    /// status and informs the delegate if a change in status takes place.
    /// - Parameter completion: Called with the current status of the payment intent when the fetch completes
    public func pollOnce(completion: ((STPPaymentIntentStatus) -> Void)? = nil) {
        fetchStatus(forceFetch: true, completion: completion)
    }

    // MARK: - Private functions

    private func fetchStatus(forceFetch: Bool = false, completion: ((STPPaymentIntentStatus) -> Void)? = nil) {
        intentRetriever.retrievePaymentIntent(withClientSecret: clientSecret) { [weak self] paymentIntent, _ in
            guard let self = self else { return }
            guard let paymentIntent = paymentIntent else { return }
            completion?(paymentIntent.status)

            // If latest status is different than last known status notify our delegate
            if paymentIntent.status != self.lastStatus,
               (self.isPolling || forceFetch) { // don't notify our delegate if polling is suspended, could happen if network request is in-flight
                self.lastStatus = paymentIntent.status
                self.delegate?.didUpdate(paymentIntent: paymentIntent)
            }

            // If we are actively polling schedule another fetch
            if self.isPolling {
                self.retryAfterInterval()
            }
        }
    }

    private func retryAfterInterval() {
        nextPollWorkItem = DispatchWorkItem { [weak self] in
            self?.fetchStatus()
        }

        guard let nextPollWorkItem = nextPollWorkItem else { return }
        pollingQueue.asyncAfter(deadline: .now() + retryInterval, execute: nextPollWorkItem)
    }
}
