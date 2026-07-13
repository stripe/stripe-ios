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
}

/// Shared wallet ownership verification helpers used by the example app.
enum WalletOwnershipVerification {

    /// An alert used when the app cannot start wallet ownership verification.
    static let unavailableAlert = Alert(
        title: "Wallet verification unavailable",
        message: "Wallet ownership verification couldn't be started. Please try again."
    )

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
                        message: errorMessage(for: error)
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

    /// Returns a user-facing verification error message.
    /// - Parameter error: The error returned while verifying wallet ownership.
    private static func errorMessage(for error: Error) -> String {
       if let error = error as? StripeCryptoOnrampError {
            return error.userMessage
        } else {
            return error.localizedDescription
        }
    }
}
