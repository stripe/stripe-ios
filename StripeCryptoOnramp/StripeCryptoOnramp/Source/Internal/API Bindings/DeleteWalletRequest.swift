//
//  DeleteWalletRequest.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/5/26.
//

import Foundation

/// Encodable model passed to the `/v1/crypto/internal/wallet` endpoint to delete a wallet.
struct DeleteWalletRequest: Encodable {

    /// The ID of the crypto wallet to delete.
    let walletToken: String

    /// Contains credentials required to make the request.
    let credentials: Credentials

    /// Creates a new `DeleteWalletRequest` instance.
    /// - Parameters:
    ///   - walletId: The ID of the crypto wallet to delete.
    ///   - consumerSessionClientSecret: Contains credentials required to make the request.
    init(walletId: String, consumerSessionClientSecret: String) {
        walletToken = walletId
        credentials = Credentials(consumerSessionClientSecret: consumerSessionClientSecret)
    }
}
