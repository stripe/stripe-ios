//
//  CryptoOnrampCoordinator.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/14/25.
//

import Foundation
@_spi(STP) import StripePaymentSheet

/// Protocol describing a type that coordinates headless Link user authentication, identity verification, and payment, leaving most of the associated UI up to the client.
@_spi(CryptoOnrampSDKPreview)
public protocol CryptoOnrampCoordinatorProtocol {

    /// Creates a `CryptoOnrampCoordinator` to facilitate authentication, identity verification, and payment.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this coordinator. Defaults to `.shared`.
    /// - Parameter appearance: Customizable appearance-related configuration for any Stripe-provided UI.
    /// - Returns: A configured `CryptoOnrampCoordinator`.
    static func create(apiClient: STPAPIClient, appearance: Appearance) async throws -> Self

    /// Looks up whether the provided email is associated with an existing Link consumer.
    ///
    /// - Parameter email: The email address to look up.
    /// - Returns: Returns `true` if the email is associated with an existing Link consumer, or `false` otherwise.
    func lookupConsumer(with email: String) async throws -> Bool
}

/// Coordinates headless Link user authentication and identity verification, leaving most of the UI to the client.
@_spi(CryptoOnrampSDKPreview)
public final class CryptoOnrampCoordinator: CryptoOnrampCoordinatorProtocol {
    private let linkController: LinkController
    private let apiClient: STPAPIClient
    private let appearance: Appearance

    private init(linkController: LinkController, apiClient: STPAPIClient = .shared, appearance: Appearance) {
        self.linkController = linkController
        self.apiClient = apiClient
        self.appearance = appearance
    }

    // MARK: - CryptoOnrampCoordinatorProtocol

    public static func create(apiClient: STPAPIClient = .shared, appearance: Appearance) async throws -> CryptoOnrampCoordinator {
        let linkController = try await LinkController.create(apiClient: apiClient, mode: .payment)
        return CryptoOnrampCoordinator(
            linkController: linkController,
            apiClient: apiClient,
            appearance: appearance
        )
    }

    public func lookupConsumer(with email: String) async throws -> Bool {
        return try await linkController.lookupConsumer(with: email)
    }
}
