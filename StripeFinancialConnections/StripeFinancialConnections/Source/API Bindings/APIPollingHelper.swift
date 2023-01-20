//
//  APIPollingHelper.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/2/22.
//

import Foundation
@_spi(STP) import StripeCore

final class APIPollingHelper<Value> {

    struct PollTimingOptions {
        let initialPollDelay: TimeInterval
        let maxNumberOfRetries: Int
        let retryInterval: TimeInterval

        init(
            initialPollDelay: TimeInterval = 1.75,
            maxNumberOfRetries: Int = 180,
            retryInterval: TimeInterval = 0.25
        ) {
            self.initialPollDelay = initialPollDelay
            self.maxNumberOfRetries = maxNumberOfRetries
            self.retryInterval = retryInterval
        }
    }

    private let apiCall: () -> Future<Value>
    private let originalPromise: Promise<Value>
    private let pollTimingOptions: PollTimingOptions

    private var strongSelfReference: APIPollingHelper<Value>?
    private var currentApiCallTimer: Timer?
    private var numberOfRetriesLeft: Int

    init(
        apiCall: @escaping () -> Future<Value>,
        pollTimingOptions: PollTimingOptions = PollTimingOptions()
    ) {
        self.apiCall = apiCall
        self.pollTimingOptions = pollTimingOptions
        self.numberOfRetriesLeft = pollTimingOptions.maxNumberOfRetries
        self.originalPromise = Promise<Value>()
    }

    deinit {
        invalidateTimer()
    }

    func startPollingApiCall() -> Future<Value> {
        assertMainQueue()
        // polling helper will keep a strong reference to itself
        // until `originalPromise` is fulfilled
        self.strongSelfReference = self
        originalPromise
            .observe(on: .main) { [weak self] _ in
                // clear the strong reference once the original
                // promise is fulfilled...
                self?.strongSelfReference = nil
            }

        callApi(afterDelay: pollTimingOptions.initialPollDelay)
        return originalPromise
    }

    private func callApi(afterDelay delay: TimeInterval) {
        assertMainQueue()
        self.currentApiCallTimer = Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: false,
            block: { [weak self] _ in
                guard let self = self else { return }
                self.invalidateTimer()
                self.callApi()
            }
        )
    }

    private func callApi() {
        assertMainQueue()
        apiCall()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.originalPromise.fullfill(with: result)
                case .failure(let error):
                    if self.numberOfRetriesLeft > 0,
                        let error = error as? StripeError,
                        case .apiError(let apiError) = error,
                        // we want to retry in the case of a 202
                        apiError.statusCode == 202
                    {
                        self.numberOfRetriesLeft -= 1
                        self.callApi(afterDelay: self.pollTimingOptions.retryInterval)
                    } else {
                        self.originalPromise.fullfill(with: result)
                    }
                }
            }
    }

    private func invalidateTimer() {
        currentApiCallTimer?.invalidate()
        currentApiCallTimer = nil
    }
}
