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
                // Add some backoff time with a little bit of jitter:
                let delayTime = TimeInterval(
                    pow(Double(1 + StripeAPI.maxRetries - retryCount), Double(2))
                        + .random(in: 0..<0.5)
                )

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
}
