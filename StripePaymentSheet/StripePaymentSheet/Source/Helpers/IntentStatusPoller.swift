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

class IntentStatusPoller {
    let retryInterval: TimeInterval
    let apiClient: STPAPIClient
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

    init(retryInterval: TimeInterval, apiClient: STPAPIClient, clientSecret: String) {
        self.retryInterval = retryInterval
        self.apiClient = apiClient
        self.clientSecret = clientSecret
    }

    // MARK: Public APIs

    public func beginPolling() {
        isPolling = true
    }

    public func suspendPolling() {
        isPolling = false
    }

    public func fetchStatus(forceFetch: Bool = false) {
        apiClient.retrievePaymentIntent(withClientSecret: clientSecret) { [weak self] paymentIntent, _ in
            guard let self = self else { return }

            // If latest status is different than last known status notify our delegate
            if let paymentIntent = paymentIntent,
               paymentIntent.status != self.lastStatus,
               isPolling || forceFetch { // don't notify our delegate if polling is suspended, could happen if network request is in-flight
                self.lastStatus = paymentIntent.status
                self.delegate?.didUpdate(paymentIntent: paymentIntent)
            }

            // If we are activly polling schedule another fetch
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
