//
//  STPSourcePoller.swift
//  StripePayments
//
//  Created by Ben Guo on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

class STPSourcePoller: NSObject {
    required init(
        apiClient: STPAPIClient,
        clientSecret: String,
        sourceID: String,
        timeout: TimeInterval,
        completion: @escaping STPSourceCompletionBlock
    ) {
        self.apiClient = apiClient
        self.sourceID = sourceID
        self.clientSecret = clientSecret
        self.completion = completion
        pollInterval = DefaultPollInterval
        self.timeout = timeout
        startTime = Date()
        retryCount = 0
        requestCount = 0
        pollingPaused = false
        pollingStopped = false
        super.init()
        poll(after: 0, lastError: nil)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(restartPolling),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(restartPolling),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(pausePolling),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(pausePolling),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    // Stops polling and cancels the request in progress.
    func stopPolling() {
        pollingStopped = true
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    private weak var apiClient: STPAPIClient?
    private var sourceID: String
    private var clientSecret: String
    private var completion: STPSourceCompletionBlock
    private var latestSource: STPSource?
    private var pollInterval: TimeInterval = 0.0
    private var timeout: TimeInterval = 0.0
    private var timer: Timer?
    private var startTime: Date
    private var retryCount = 0
    private var requestCount = 0
    private var pollingPaused = false
    private var pollingStopped = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func poll(after interval: TimeInterval, lastError error: Error?) {
        let totalTime: TimeInterval = Date().timeIntervalSince(startTime)
        let shouldTimeout =
            requestCount > 0
            && ((totalTime) >= TimeInterval(min(timeout, MaxTimeout)) || retryCount >= MaxRetries)
        if apiClient == nil || shouldTimeout {
            cleanupAndFireCompletion(
                with: latestSource,
                error: error
            )
            return
        }
        if pollingPaused || pollingStopped {
            return
        }
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(_poll),
            userInfo: nil,
            repeats: false
        )
    }

    @objc func _poll() {
        timer = nil
        let application = UIApplication.shared
        var bgTaskID: UIBackgroundTaskIdentifier = .invalid
        bgTaskID = application.beginBackgroundTask(expirationHandler: {
            application.endBackgroundTask(bgTaskID)
            bgTaskID = .invalid
        })
        apiClient?.retrieveSource(
            withId: sourceID,
            clientSecret: clientSecret,
            responseCompletion: { source, response, error in
                self._continue(with: source, response: response, error: error as NSError?)
                self.requestCount += 1
                application.endBackgroundTask(bgTaskID)
                bgTaskID = .invalid
            }
        )
    }

    func _continue(
        with source: STPSource?,
        response: HTTPURLResponse?,
        error: NSError?
    ) {
        if let response = response {
            let status = response.statusCode
            if status >= 400 && status < 500 {
                // Don't retry requests that 4xx
                cleanupAndFireCompletion(
                    with: latestSource,
                    error: error
                )
            } else if status == 200 {
                pollInterval = DefaultPollInterval
                retryCount = 0
                latestSource = source
                if shouldContinuePollingSource(source) {
                    poll(after: pollInterval, lastError: nil)
                } else {
                    cleanupAndFireCompletion(
                        with: latestSource,
                        error: nil
                    )
                }
            } else {
                // Backoff and increment retry count
                pollInterval = TimeInterval(min(pollInterval * 2, MaxPollInterval))
                retryCount += 1
                poll(after: pollInterval, lastError: error)
            }
        } else {
            // Retry if there's a connectivity error
            if let error = error,
                error.code == CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue
                    || error.code == CFNetworkErrors.cfurlErrorNetworkConnectionLost.rawValue
            {
                retryCount += 1
                poll(after: pollInterval, lastError: error)
            } else {
                // Don't call completion if the request was cancelled
                if let error = error, error.code != CFNetworkErrors.cfurlErrorCancelled.rawValue {
                    cleanupAndFireCompletion(
                        with: latestSource,
                        error: error
                    )
                }
                stopPolling()
            }
        }
    }

    func shouldContinuePollingSource(_ source: STPSource?) -> Bool {
        if source == nil {
            return false
        }
        return source?.status == .pending
    }

    @objc func restartPolling() {
        if pollingStopped {
            return
        }
        pollingPaused = false
        if timer == nil {
            poll(after: 0, lastError: nil)
        }
    }

    // Pauses polling, without canceling the request in progress.
    @objc func pausePolling() {
        pollingPaused = true
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    func cleanupAndFireCompletion(
        with source: STPSource?,
        error: Error?
    ) {
        if !pollingStopped {
            DispatchQueue.main.async(execute: {
                if error == nil && source == nil {
                    self.completion(nil, NSError.stp_genericConnectionError())
                } else {
                    self.completion(source, error)
                }
            })
            stopPolling()
        }
    }
}

private let DefaultPollInterval: TimeInterval = 1.5
private let MaxPollInterval: TimeInterval = 24
// Stop polling after 5 minutes
private let MaxTimeout: TimeInterval = 60 * 5
// Stop polling after 5 consecutive non-200 responses
private let MaxRetries: Int = 5
