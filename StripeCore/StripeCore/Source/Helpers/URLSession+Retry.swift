//
//  URLSession+Retry.swift
//  StripeCore
//
//  Created by David Estes on 3/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension URLSession {
    @_spi(STP) public func stp_performDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void,
        retryCount: Int = StripeAPI.maxRetries
    ) {
        let task = dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 429,
                retryCount > 0
            {
                let delayTime = Self.retryDelay(retryCount: retryCount)
                let fireDate = Date() + delayTime
                self.delegateQueue.schedule(after: .init(fireDate)) {
                    self.stp_performDataTask(
                        with: request,
                        completionHandler: completionHandler,
                        retryCount: retryCount - 1
                    )
                }
            } else {
                completionHandler(data, response, error)
            }
        }
        task.resume()
    }

    func stp_performUploadTask(
        with request: URLRequest,
        from body: Data,
        delegate: URLSessionTaskDelegate
    ) async throws -> (Data, URLResponse) {
        var retryCount = StripeAPI.maxRetries
        while true {
            try Task.checkCancellation()
            let (data, response) = try await upload(for: request, from: body, delegate: delegate)
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 429,
                retryCount > 0
            else {
                return (data, response)
            }
            let delayTime = Self.retryDelay(retryCount: retryCount)
            retryCount -= 1
            try await Task.sleep(nanoseconds: UInt64(delayTime * 1_000_000_000))
        }
    }

    private static func retryDelay(retryCount: Int) -> TimeInterval {
        // Add some backoff time with a little bit of jitter:
        return TimeInterval(
            pow(Double(1 + StripeAPI.maxRetries - retryCount), Double(2))
                + .random(in: 0..<0.5)
        )
    }
}
