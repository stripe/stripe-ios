//
//  CreateOnrampSessionRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct CreateOnrampSessionRequest: Encodable {
    let uiMode = "headless"
    let paymentToken: String
    let sourceAmount: Decimal
    let sourceCurrency: String
    let destinationCurrency: String
    let destinationNetwork: String
    let walletAddress: String
    let cryptoCustomerId: String
    let customerIpAddress: String
}
