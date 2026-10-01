//
//  CreateOnrampSessionResponse.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 8/19/25.
//

import Foundation

/// The response format for `/checkout` and `/quote` matches that of `/create_onramp_session`, so we use the same underlying model.
typealias CheckoutResponse = CreateOnrampSessionResponse
typealias QuoteResponse = CreateOnrampSessionResponse

struct CreateOnrampSessionResponse: Decodable, Hashable {
    struct TransactionDetails: Decodable, Hashable {
        struct Fees: Decodable, Hashable {
            /// Present only when `fee_responsibility` is not `"consumer"`. Contains computed fee amounts only;
            /// `fee_responsibility` itself lives at the session level.
            struct Subsidy: Decodable, Hashable {
                /// What the fee would have been without the subsidy.
                let originalFee: String

                /// What the consumer pays after the subsidy (`"0.00"` when `fee_responsibility` is `"merchant"`).
                let totalFeeAfterSubsidization: String
            }

            let networkFeeAmount: String
            let transactionFeeAmount: String
            let subsidy: Subsidy?
        }

        let destinationCurrency: String
        let destinationAmount: String
        let destinationNetwork: String
        let fees: Fees
        let lastError: String?
        let lockWalletAddress: Bool
        let quoteExpiration: Date
        let sourceCurrency: String
        let sourceAmount: String
        let destinationCurrencies: [String]
        let destinationNetworks: [String]
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
    let metadata: [String: String]?
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
