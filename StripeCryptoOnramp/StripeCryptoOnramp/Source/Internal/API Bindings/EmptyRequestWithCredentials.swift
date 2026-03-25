//
//  EmptyRequestWithCredentials.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/17/25.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/customers` and `crypto/internal/kyc_data_retrieve` endpoints.
struct EmptyRequestWithCredentials: Encodable {

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `EmptyRequestWithCredentials` instance.
    /// - Parameter consumerSessionClientSecret: Contains credentials required to make the request.
    init(consumerSessionClientSecret: String) {
        credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}
