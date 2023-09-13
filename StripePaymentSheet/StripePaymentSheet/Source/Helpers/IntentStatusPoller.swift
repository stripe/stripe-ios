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

    init(apiClient: STPAPIClient, clientSecret: String) {
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

    // MARK: Private functions

    private func fetchStatus() {
        apiClient.retrievePaymentIntent(withClientSecret: clientSecret) { [weak self] paymentIntent, _ in
            guard let isPolling = self?.isPolling else {
                return
            }

            // If latest status is different than last known status notify our delegate
            if let paymentIntent = paymentIntent,
               paymentIntent.status != self?.lastStatus,
               isPolling {
                self?.lastStatus = paymentIntent.status
                self?.delegate?.didUpdate(paymentIntent: paymentIntent)
            }

            // If we are polling, fetch again in 1 second
            if isPolling {
                self?.pollingQueue.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.fetchStatus()
                }
            }
        }
    }
}
