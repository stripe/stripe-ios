//
//  RetrieveCryptoCustomerRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/customers/:id` endpoint.
struct RetrieveCryptoCustomerRequest: Encodable {

    /// Contains credentials required to retrieve the CryptoCustomer.
    let credentials: Credentials
}
