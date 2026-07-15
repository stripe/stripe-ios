//
//  WalletOwnershipVerification.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 6/29/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// Context needed to request and submit wallet ownership verification.
struct WalletOwnershipVerificationContext {

    /// The wallet address being verified.
    let walletAddress: String

    /// The Stripe crypto network for the wallet address.
    let network: CryptoNetwork

    /// Creates a wallet ownership verification context.
    /// - Parameters:
    ///   - walletAddress: The wallet address being verified.
    ///   - network: The Stripe crypto network for the wallet address.
    init(walletAddress: String, network: CryptoNetwork) {
        self.walletAddress = walletAddress
        self.network = network
    }

    /// Creates a wallet ownership verification context from a customer wallet response.
    /// - Parameter wallet: The customer wallet response from the example app backend.
    init?(wallet: CustomerWalletsResponse.Wallet) {
        guard let network = CryptoNetwork(rawValue: wallet.network) else {
            return nil
        }

        self.init(walletAddress: wallet.walletAddress, network: network)
    }

    /// Creates a wallet ownership verification context from transaction details returned by session creation.
    /// - Parameter transactionDetails: The transaction details from a create-onramp-session response.
    init?(transactionDetails: CreateOnrampSessionResponse.TransactionDetails) {
        guard let network = CryptoNetwork(rawValue: transactionDetails.destinationNetwork) else {
            return nil
        }

        self.init(walletAddress: transactionDetails.walletAddress, network: network)
    }
}

/// Shared wallet ownership verification helpers used by the example app.
enum WalletOwnershipVerification {

    /// The `lastError` value indicating wallet ownership verification is required.
    static let requiredLastError = "wallet_ownership_verification_required"

    /// An alert used when the app cannot start wallet ownership verification.
    static let unavailableAlert = Alert(
        title: "Wallet verification unavailable",
        message: "Wallet ownership verification couldn't be started. Please try again."
    )

    /// Returns whether a create-onramp-session response requires wallet ownership verification.
    /// - Parameter response: The create-onramp-session response to inspect.
    static func isRequired(for response: CreateOnrampSessionResponse) -> Bool {
        response.transactionDetails.lastError == requiredLastError
    }

    /// Starts wallet ownership verification and updates shared loading and alert UI state.
    /// - Parameters:
    ///   - context: Context needed to verify wallet ownership.
    ///   - coordinator: The coordinator used to call wallet ownership APIs.
    ///   - isLoading: Binding that controls the example app's shared loading state.
    ///   - alert: Binding used to present verification failure alerts.
    ///   - onVerified: Called when Stripe returns the wallet as verified.
    static func startVerification(
        context: WalletOwnershipVerificationContext,
        coordinator: CryptoOnrampCoordinator,
        isLoading: Binding<Bool>,
        alert: Binding<Alert?>,
        onVerified: @escaping @MainActor () -> Void
    ) {
        isLoading.wrappedValue = true
        alert.wrappedValue = nil

        Task {
            do {
                let wallet = try await verify(
                    context: context,
                    coordinator: coordinator
                )

                await MainActor.run {
                    isLoading.wrappedValue = false
                    if wallet.verifiedOwnership {
                        onVerified()
                    } else {
                        alert.wrappedValue = Alert(
                            title: "Wallet verification failed",
                            message: "Stripe did not mark this wallet as verified. Please try again."
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert.wrappedValue = Alert(
                        title: "Wallet verification failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    /// Requests a wallet ownership challenge, signs it, and submits the signature.
    /// - Parameters:
    ///   - context: Context needed to verify wallet ownership.
    ///   - coordinator: The coordinator used to call wallet ownership APIs.
    private static func verify(
        context: WalletOwnershipVerificationContext,
        coordinator: CryptoOnrampCoordinator
    ) async throws -> CryptoConsumerWallet {
        let challenge = try await coordinator.getWalletOwnershipChallenge(
            walletAddress: context.walletAddress,
            network: context.network
        )

        // Note: This constant signature is accepted in test mode. For live mode, an actual signature
        // of `challenge.message` must be produced using the wallet.
        let signature = "abcd"
        return try await coordinator.submitWalletOwnershipSignature(
            challengeId: challenge.challengeId,
            signature: signature
        )
    }
}

/// Error used to interrupt the example app flow when wallet ownership verification is required.
struct WalletOwnershipVerificationRequiredError: Error {

    /// The response that indicated wallet ownership verification is required.
    let response: CreateOnrampSessionResponse
}

/// Convenience helpers for interpreting wallet ownership verification requirements.
extension CreateOnrampSessionResponse {

    /// Whether this response indicates wallet ownership verification is required before continuing.
    var requiresWalletOwnershipVerification: Bool {
        WalletOwnershipVerification.isRequired(for: self)
    }
}
