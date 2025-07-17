//
//  CryptoOnrampCoordinator.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/14/25.
//

import Foundation
@_spi(STP) import StripePaymentSheet
import UIKit

/// Protocol describing a type that coordinates headless Link user authentication, identity verification, and payment, leaving most of the associated UI up to the client.
@_spi(CryptoOnrampSDKPreview)
public protocol CryptoOnrampCoordinatorProtocol {

    /// Creates a `CryptoOnrampCoordinator` to facilitate authentication, identity verification, and payment.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this coordinator. Defaults to `.shared`.
    /// - Parameter appearance: Customizable appearance-related configuration for any Stripe-provided UI.
    /// - Returns: A configured `CryptoOnrampCoordinator`.
    static func create(apiClient: STPAPIClient, appearance: Appearance) async throws -> Self

    /// Determines whether the user with the specified email is already a Link user.
    ///
    /// - Parameter email: The email address of the user in question.
    /// - Returns: Whether the email corresponds to an already registered Link user.
    func isLinkUser(email: String) async throws -> Bool

    /// Registers a new Link user with the provided details.
    /// `isLinkUser` must be called before this.
    ///
    /// - Parameter fullName: The full name of the user.
    /// - Parameter phone: The phone number of the user. Expected to be in E.164 format.
    /// - Parameter country: The country code of the user.
    /// Throws if `isLinkUser` was not called prior to this, or an API error occurs.
    func registerNewLinkUser(phone: String, country: String, fullName: String?) async throws

    /// Presents the Link verification flow for an existing user.
    /// `isLinkUser` must be called before this.
    ///
    /// - Parameter viewController: The view controller from which to present the authentication flow.
    /// - Returns: An `AuthenticationResult` indicating whether authentication was completed or canceled.
    /// Throws if `isLinkUser` was not called prior to this, or an API error occurs.
    func authenticateExistingLinkUser(from viewController: UIViewController) async throws -> LinkController.AuthenticationResult
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

    public func isLinkUser(email: String) async throws -> Bool {
        return try await linkController.lookupConsumer(with: email)
    }

    public func registerNewLinkUser(phone: String, country: String, fullName: String?) async throws {
        return try await linkController.registerNewLinkUser(fullName: fullName, phone: phone, country: country)
    }

    public func authenticateExistingLinkUser(from viewController: UIViewController) async throws -> LinkController.AuthenticationResult {
        return try await linkController.presentForVerification(from: viewController)
    }
}
