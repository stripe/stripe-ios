//
//  IntentStatusPoller.swift
//  StripeiOS
//
//  Created by Nick Porter on 9/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeCore

protocol IntentStatusPollerDelegate: AnyObject {
    func didUpdate(paymentIntent: STPPaymentIntent)
}

class IntentStatusPoller {
    let apiClient: STPAPIClient
    let clientSecret: String
    let maxRetries: Int
    
    private var lastStatus: STPPaymentIntentStatus = .unknown
    private var retryCount = 0
    private let pollingQueue = DispatchQueue(label: "com.stripe.intent.status.queue")
    private var nextPollWorkItem: DispatchWorkItem?
    
    weak var delegate: IntentStatusPollerDelegate?
    
    var isPolling: Bool = false {
        didSet {
            // Start polling if we weren't already polling
            if !oldValue && isPolling {
                forcePoll()
            } else if !isPolling {
                nextPollWorkItem?.cancel()
            }
        }
    }
    
    init(apiClient: STPAPIClient, clientSecret: String, maxRetries: Int) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.maxRetries = maxRetries
    }
    
    // MARK: Public APIs
    
    public func beginPolling() {
        isPolling = true
    }
    
    public func suspendPolling() {
        isPolling = false
    }
    
    public func forcePoll() {
        fetchStatus(forcePoll: true)
    }
    
    // MARK: Private functions
    
    private func fetchStatus(forcePoll: Bool = false) {
        guard forcePoll || (isPolling && retryCount < maxRetries) else { return }
        retryCount += 1
        
        apiClient.retrievePaymentIntent(withClientSecret: clientSecret) { [weak self] paymentIntent, error in
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
            
            // If we are polling and have retries left, schedule a status fetch
            if isPolling, let maxRetries = self?.maxRetries, let retryCount = self?.retryCount {
                self?.retryWithExponentialDelay(retryCount: maxRetries - retryCount) {
                    self?.fetchStatus()
                }
            }
        }
    }
    
    private func retryWithExponentialDelay(retryCount: Int, block: @escaping () -> ()) {
        // Add some backoff time
        let delayTime = TimeInterval(
            pow(Double(1 + maxRetries - retryCount), Double(2))
        )
        
        nextPollWorkItem = DispatchWorkItem {
            block()
        }
        
        guard let nextPollWorkItem = nextPollWorkItem else { return }
        pollingQueue.asyncAfter(deadline: .now() + delayTime, execute: nextPollWorkItem)
    }
}
