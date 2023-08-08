//
//  URLSession+Retry.swift
//  StripeCore
//
//  Created by David Estes on 3/26/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

public class STPWeirdStuff {
    public static var weirdStuffEnabled: Bool = true {
        didSet {
            UIApplication.shared.windows.first?.layer.speed = weirdStuffEnabled ? 0.2 : 1.0
        }
    }
}
extension URLSession {
    @_spi(STP) public func stp_performDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void,
        retryCount: Int = StripeAPI.maxRetries
    ) {
        let slowNetworkTime = TimeInterval(.random(in: 0.0..<5.0))
        var slowFireDate = Date() + slowNetworkTime
        if !STPWeirdStuff.weirdStuffEnabled {
            slowFireDate = Date()
        }
        self.delegateQueue.schedule(after: .init(slowFireDate)) {
            var fakeConnectionReset = .random(in: 0..<100) <= 10
            if !STPWeirdStuff.weirdStuffEnabled {
                fakeConnectionReset = false
            }

            if fakeConnectionReset {
                let connectionResetError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
                completionHandler(nil, nil, connectionResetError)
                return
            }

            let task = self.dataTask(with: request) { (data, response, error) in
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
}
