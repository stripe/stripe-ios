//
//  RequestConfiguration.swift
//  StripeCore
//
//  Created by Carlos Munoz on 5/12/25.
//
@_spi(STP) public struct STPRequestConfiguration {

    /// A Boolean value that determines whether to automatically retry the network request
    /// when a response returns a 429 (Too Many Requests) HTTP status code.
    ///
    /// - true: Retry the request upon receiving a 429 response.
    /// - false: Do not automatically retry the request.
    let retryOn429: Bool

    public init(retryOn429: Bool = true) {
        self.retryOn429 = retryOn429
    }
}
