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

    var isPolling: Bool = false {
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
    public func pollOnce() {
        fetchStatus(forceFetch: true)
    }

    // MARK: - Private functions

    private func fetchStatus(forceFetch: Bool = false) {
        intentRetriever.retrievePaymentIntent(withClientSecret: clientSecret) { [weak self] paymentIntent, _ in
            guard let self = self else { return }

            // If latest status is different than last known status notify our delegate
            if let paymentIntent = paymentIntent,
               paymentIntent.status != self.lastStatus,
               (isPolling || forceFetch) { // don't notify our delegate if polling is suspended, could happen if network request is in-flight
                self.lastStatus = paymentIntent.status
                self.delegate?.didUpdate(paymentIntent: paymentIntent)
            }

            // If we are actively polling schedule another fetch
            if isPolling {
                self.retryAfterInterval { [weak self] in
                    self?.fetchStatus()
                }
            }
        }
    }

    private func retryAfterInterval(block: @escaping () -> Void) {
        nextPollWorkItem = DispatchWorkItem {
            block()
        }

        guard let nextPollWorkItem = nextPollWorkItem else { return }
        pollingQueue.asyncAfter(deadline: .now() + retryInterval, execute: nextPollWorkItem)
    }
}
