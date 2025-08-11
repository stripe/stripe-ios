//
//  CustomerRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/17/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/customers` endpoint.
struct CustomerRequest: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `CustomerRequest` instance.
    /// - Parameter consumerSessionClientSecret: Contains credentials required to make the request.
    init(consumerSessionClientSecret: String) {
        credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}
