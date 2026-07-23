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

    /// Whether the wallet is being verified in test mode.
    let isTestMode: Bool

    /// Creates a wallet ownership verification context.
    /// - Parameters:
    ///   - walletAddress: The wallet address being verified.
    ///   - network: The Stripe crypto network for the wallet address.
    ///   - isTestMode: Whether the wallet is being verified in test mode.
    init(walletAddress: String, network: CryptoNetwork, isTestMode: Bool) {
        self.walletAddress = walletAddress
        self.network = network
        self.isTestMode = isTestMode
    }

    /// Creates a wallet ownership verification context from a customer wallet response.
    /// - Parameter wallet: The customer wallet response from the example app backend.
    init?(wallet: CustomerWalletsResponse.Wallet) {
        guard let network = CryptoNetwork(rawValue: wallet.network) else {
            return nil
        }

        self.init(
            walletAddress: wallet.walletAddress,
            network: network,
            isTestMode: !wallet.livemode
        )
    }

    /// Creates a wallet ownership verification context from transaction details returned by session creation.
    /// - Parameters:
    ///   - transactionDetails: The transaction details from a create-onramp-session response.
    ///   - isTestMode: Whether the wallet is being verified in test mode.
    init?(transactionDetails: CreateOnrampSessionResponse.TransactionDetails, isTestMode: Bool) {
        guard let network = CryptoNetwork(rawValue: transactionDetails.destinationNetwork) else {
            return nil
        }

        self.init(
            walletAddress: transactionDetails.walletAddress,
            network: network,
            isTestMode: isTestMode
        )
    }
}

/// A server-issued challenge ready to be displayed for wallet ownership verification.
struct WalletOwnershipVerificationSession: Identifiable {

    /// The challenge that must be signed.
    let challenge: WalletOwnershipChallenge

    /// Whether the wallet is being verified in test mode.
    let isTestMode: Bool

    // MARK: - Identifiable

    /// The identifier used to present this challenge in a sheet.
    var id: String {
        challenge.challengeId
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

    /// Requests a wallet ownership challenge and updates shared loading and alert UI state.
    /// - Parameters:
    ///   - context: Context needed to verify wallet ownership.
    ///   - coordinator: The coordinator used to call wallet ownership APIs.
    ///   - isLoading: Binding that controls the example app's shared loading state.
    ///   - alert: Binding used to present verification failure alerts.
    ///   - onChallengeReceived: Called when the challenge is ready to display.
    static func requestChallenge(
        context: WalletOwnershipVerificationContext,
        coordinator: CryptoOnrampCoordinator,
        isLoading: Binding<Bool>,
        alert: Binding<Alert?>,
        onChallengeReceived: @escaping @MainActor (WalletOwnershipVerificationSession) -> Void
    ) {
        isLoading.wrappedValue = true
        alert.wrappedValue = nil

        Task {
            do {
                let challenge = try await coordinator.getWalletOwnershipChallenge(
                    walletAddress: context.walletAddress,
                    network: context.network
                )

                await MainActor.run {
                    isLoading.wrappedValue = false
                    onChallengeReceived(
                        WalletOwnershipVerificationSession(
                            challenge: challenge,
                            isTestMode: context.isTestMode
                        )
                    )
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
}

/// Convenience helpers for interpreting wallet ownership verification requirements.
extension CreateOnrampSessionResponse {

    /// Whether this response indicates wallet ownership verification is required before continuing.
    var requiresWalletOwnershipVerification: Bool {
        WalletOwnershipVerification.isRequired(for: self)
    }
}
