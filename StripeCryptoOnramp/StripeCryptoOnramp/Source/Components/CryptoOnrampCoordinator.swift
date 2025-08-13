//
//  CryptoOnrampCoordinator.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/14/25.
//

import Foundation

@_spi(STP) import StripeIdentity
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
    static func create(apiClient: STPAPIClient, appearance: LinkAppearance) async throws -> Self

    /// Looks up whether the provided email is associated with an existing Link consumer.
    ///
    /// - Parameter email: The email address to look up.
    /// - Returns: Returns `true` if the email is associated with an existing Link consumer, or `false` otherwise.
    func lookupConsumer(with email: String) async throws -> Bool

    /// Registers a new Link user with the provided details.
    /// `lookupConsumer` must be called before this.
    ///
    /// - Parameter fullName: The full name of the user.
    /// - Parameter phone: The phone number of the user. Phone number must be in E.164 format (e.g., +12125551234), otherwise an error will be thrown.
    /// - Parameter country: The country code of the user.
    /// - Returns: The crypto customer ID.
    /// Throws if `lookupConsumer` was not called prior to this, or an API error occurs.
    func registerLinkUser(fullName: String?, phone: String, country: String) async throws -> String

    /// Presents the Link verification flow for an existing user.
    /// `lookupConsumer` must be called before this.
    ///
    /// - Parameter viewController: The view controller from which to present the verification flow.
    /// - Returns: A `VerificationResult` indicating whether verification was completed or canceled.
    ///   If verification completes, a crypto customer ID will be included in the result.
    /// Throws if `lookupConsumer` was not called prior to this, or an API error occurs.
    func presentForVerification(from viewController: UIViewController) async throws -> VerificationResult

    /// Attaches the specific KYC info to the current Link user. Requires an authenticated Link user.
    ///
    /// - Parameter info: The KYC info to attach to the Link user.
    /// - Throws an error if an error occurs.
    func collectKYCInfo(info: KycInfo) async throws

    /// Creates an identity verification session and launches the verification flow.
    ///
    /// - Parameter viewController: The view controller from which to present the verification flow.
    /// - Returns: An `IdentityVerificationResult` representing the outcome of the verification process.
    func promptForIdentityVerification(from viewController: UIViewController) async throws -> IdentityVerificationResult

    /// Registers the given crypto wallet address to the current Link account.
    ///
    /// - Parameter walletAddress: The crypto wallet address to register.
    /// - Parameter network: The crypto network for the wallet address.
    func collectWalletAddress(walletAddress: String, network: CryptoNetwork) async throws

    /// Presents the Link sheet to collect a customer's payment method.
    /// - Parameter viewController: The view controller from which to present the Link sheet.
    /// - Returns: A `PaymentMethodPreview` if the user selected a payment method, or `nil` otherwise.
    func collectPaymentMethod(from viewController: UIViewController) async -> PaymentMethodPreview?

    /// Creates a crypto payment token for the selected payment method.
    /// - Returns: The crypto payment token ID.
    func createCryptoPaymentToken() async throws -> String
}

/// Coordinates headless Link user authentication and identity verification, leaving most of the UI to the client.
@_spi(CryptoOnrampSDKPreview)
public final class CryptoOnrampCoordinator: CryptoOnrampCoordinatorProtocol {

    /// A subset of errors that may be thrown by `CryptoOnrampCoordinator` APIs.
    public enum Error: Swift.Error {

        /// Phone number validation failed. Phone number should be in E.164 format (e.g., +12125551234).
        case invalidPhoneFormat

        /// `ephemeralKey` is missing from the response after starting identity verification.
        case missingEphemeralKey
    }

    private let linkController: LinkController
    private let apiClient: STPAPIClient
    private let appearance: LinkAppearance

    private var linkAccountInfo: PaymentSheetLinkAccountInfoProtocol {
        get async throws {
            guard let linkAccount = await linkController.linkAccount else {
                throw LinkController.IntegrationError.noActiveLinkConsumer
            }
            return linkAccount
        }
    }

    private init(linkController: LinkController, apiClient: STPAPIClient = .shared, appearance: LinkAppearance) {
        self.linkController = linkController
        self.apiClient = apiClient
        self.appearance = appearance
    }

    // MARK: - CryptoOnrampCoordinatorProtocol

    public static func create(apiClient: STPAPIClient = .shared, appearance: LinkAppearance) async throws -> CryptoOnrampCoordinator {
        let linkController = try await LinkController.create(
            apiClient: apiClient,
            mode: .payment,
            appearance: appearance,
            requestSurface: .cryptoOnramp
        )

        return CryptoOnrampCoordinator(
            linkController: linkController,
            apiClient: apiClient,
            appearance: appearance
        )
    }

    public func lookupConsumer(with email: String) async throws -> Bool {
        return try await linkController.lookupConsumer(with: email)
    }

    public func registerLinkUser(fullName: String?, phone: String, country: String) async throws -> String {
        do {
            try await linkController.registerLinkUser(
                fullName: fullName,
                phone: phone,
                country: country,
                consentAction: .entered_phone_number_email_clicked_signup_crypto_onramp
            )
        } catch {
            if let stripeError = (error as? StripeError),
               case let .apiError(stripeAPIError) = stripeError,
               stripeAPIError.type == .invalidRequestError,
               let message = stripeAPIError.message,
               message.hasPrefix("There was an issue parsing the phone number") {
                throw Error.invalidPhoneFormat
            } else {
                throw error
            }
        }
        return try await apiClient.grantPartnerMerchantPermissions(with: linkAccountInfo).id
    }

    public func presentForVerification(from viewController: UIViewController) async throws -> VerificationResult {
        let verificationResult = try await linkController.presentForVerification(from: viewController)
        switch verificationResult {
        case .canceled:
            return .canceled
        case .completed:
            let customerId = try await apiClient.grantPartnerMerchantPermissions(with: linkAccountInfo).id
            return .completed(customerId: customerId)
        }
    }

    public func collectKYCInfo(info: KycInfo) async throws {
        try await apiClient.collectKycInfo(info: info, linkAccountInfo: linkAccountInfo)
    }

    public func promptForIdentityVerification(from viewController: UIViewController) async throws -> IdentityVerificationResult {
        let response = try await apiClient.startIdentityVerification(linkAccountInfo: linkAccountInfo)

        guard let ephemeralKey = response.ephemeralKey else {
            throw Error.missingEphemeralKey
        }

        let verificationSheet = IdentityVerificationSheet(
            verificationSessionId: response.id,
            ephemeralKeySecret: ephemeralKey,
            configuration: IdentityVerificationSheet.Configuration(
                brandLogo: await fetchMerchantImageWithFallback()
            )
        )

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                verificationSheet.present(from: viewController) { result in
                    switch result {
                    case .flowCompleted:
                        continuation.resume(returning: IdentityVerificationResult.completed)
                    case .flowCanceled:
                        continuation.resume(returning: IdentityVerificationResult.canceled)
                    case .flowFailed(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    public func collectWalletAddress(walletAddress: String, network: CryptoNetwork) async throws {
        try await apiClient.collectWalletAddress(
            walletAddress: walletAddress,
            network: network,
            linkAccountInfo: linkAccountInfo
        )
    }

    public func collectPaymentMethod(from viewController: UIViewController) async -> PaymentMethodPreview? {
        let email = try? await linkAccountInfo.email
        if let result = await linkController.collectPaymentMethod(from: viewController, with: email) {
            return PaymentMethodPreview(icon: result.icon, label: result.label, sublabel: result.sublabel)
        } else {
            return nil
        }
    }

    public func createCryptoPaymentToken() async throws -> String {
        let paymentMethod = try await linkController.createPaymentMethod()
        let paymentTokenResult = try await apiClient.createPaymentToken(
            for: paymentMethod.stripeId,
            linkAccountInfo: linkAccountInfo
        )
        return paymentTokenResult.id
    }
}

private extension CryptoOnrampCoordinator {
    func fetchMerchantImageWithFallback() async -> UIImage {
        guard let merchantLogoUrl = await linkController.merchantLogoUrl else {
            return .wallet
        }

        do {
            return try await DownloadManager.sharedManager.downloadImage(url: merchantLogoUrl)
        } catch {
            return .wallet
        }
    }
}
