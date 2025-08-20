//
//  CheckoutResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/20/25.
//

import Foundation

/// The response format for `/quote` matches that of `/checkout`, so we use the same underlying model.
typealias QuoteResponse = CheckoutResponse

struct CheckoutResponse: Decodable {
    struct TransactionDetails: Decodable {
        struct Fees: Decodable {
            let networkFeeAmount: String
            let transactionFeeAmount: String
        }

        let destinationCurrency: String
        let destinationExchangeAmount: String
        let destinationNetwork: String
        let fees: Fees
        let lastError: String?
        let lockWalletAddress: Bool
        let quoteExpiration: String
        let sourceCurrency: String
        let sourceExchangeAmount: String
        let supportedDestinationCurrencies: [String]
        let supportedDestinationNetworks: [String]
        let transactionId: String?
        let transactionLimit: Int
        let walletAddress: String
        let walletAddresses: [String]?
    }

    let id: String
    let object: String
    let clientSecret: String
    let created: Int
    let cryptoCustomerId: String
    let finishUrl: String?
    let isApplePay: Bool
    let kycDetailsProvided: Bool
    let livemode: Bool
    let metadata: [String: String]
    let paymentMethod: String
    let preferredPaymentMethod: String?
    let preferredRegion: String?
    let redirectUrl: String
    let skipQuoteScreen: Bool
    let sourceTotalAmount: String
    let status: String
    let transactionDetails: TransactionDetails
    let uiMode: String
}
