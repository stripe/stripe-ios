//
//  CreateOnrampSessionRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

struct CreateOnrampSessionRequest: Encodable {
    enum SettlementSpeed: String, Encodable {
        case instant
        case standard
    }

    let uiMode = "headless"
    let paymentToken: String
    let sourceAmount: Decimal
    let sourceCurrency: String
    let destinationCurrency: String
    let destinationNetwork: String
    let destinationCurrencies: [String]
    let destinationNetworks: [String]
    let walletAddress: String
    let customerIpAddress: String
    let settlementSpeed: SettlementSpeed

    // TODO: Temporary override to force merchant-paid fees for all onramp sessions. Remove before merging.
    let feeResponsibility = "merchant"
}
