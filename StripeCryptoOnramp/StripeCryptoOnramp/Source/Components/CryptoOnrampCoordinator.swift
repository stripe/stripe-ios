//
//  CryptoOnrampCoordinator.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/14/25.
//

import Foundation
import PassKit
import Stripe

@_spi(STP) import StripeApplePay
@_spi(STP) import StripePaymentsUI
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

    /// Presents UI to collect/select a payment method of the given type.
    ///
    /// - Parameters:
    ///   - type: The payment method type to collect. For `.card` and `.bankAccount`, this presents Link. For `.applePay(paymentRequest:)`, this presents Apple Pay using the provided `PKPaymentRequest`.
    ///   - viewController: The view controller from which to present the UI.
    /// - Returns: A `PaymentMethodPreview` describing the user’s selection, or `nil` if the user cancels.
    /// Throws an error if presentation or payment method collection fails.
    @MainActor
    func collectPaymentMethod(type: PaymentMethodType, from viewController: UIViewController) async throws -> PaymentMethodPreview?
}

/// Coordinates headless Link user authentication and identity verification, leaving most of the UI to the client.
@_spi(CryptoOnrampSDKPreview)
public final class CryptoOnrampCoordinator: NSObject, CryptoOnrampCoordinatorProtocol {

    /// A subset of errors that may be thrown by `CryptoOnrampCoordinator` APIs.
    public enum Error: Swift.Error {

        /// Phone number validation failed. Phone number should be in E.164 format (e.g., +12125551234).
        case invalidPhoneFormat

        /// `ephemeralKey` is missing from the response after starting identity verification.
        case missingEphemeralKey
    }

    private enum SelectedPaymentSource {
        case link
        case applePay(STPPaymentMethod)
    }

    private let linkController: LinkController
    private let apiClient: STPAPIClient
    private let appearance: LinkAppearance
    private var applePayCompletionContinuation: CheckedContinuation<ApplePayPaymentStatus, Swift.Error>?
    private var selectedPaymentSource: SelectedPaymentSource?

    /// Represents the selected payment method, set after successfully calling `collectPaymentMethod(type:from:)`.
    public private(set) var paymentMethodPreview: PaymentMethodPreview?

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

    @MainActor
    public func collectPaymentMethod(
        type: PaymentMethodType,
        from viewController: UIViewController
    ) async throws -> PaymentMethodPreview? {
        switch type {
        case .card, .bankAccount:
            let email = try? await linkAccountInfo.email
            guard let supportedPaymentMethodType = type.linkPaymentMethodType else {
                return nil
            }

            guard let result = await linkController.collectPaymentMethod(
                from: viewController,
                with: email,
                supportedPaymentMethodTypes: [supportedPaymentMethodType]
            ) else {
                selectedPaymentSource = nil
                paymentMethodPreview = nil
                return nil
            }

            let preview = PaymentMethodPreview(
                icon: result.icon,
                label: result.label,
                sublabel: result.sublabel
            )
            selectedPaymentSource = .link
            paymentMethodPreview = preview
            return preview
        case .applePay(let paymentRequest):
            // This presents Apple Pay and fills `applePayPaymentMethod` + `paymentMethodPreview` in the delegate.
            let status = try await presentApplePay(using: paymentRequest, from: viewController)
            switch status {
            case .success:
                guard paymentMethodPreview != nil, case .applePay = selectedPaymentSource else {
                    throw LinkController.IntegrationError.noPaymentMethodSelected
                }
                return paymentMethodPreview
            case .canceled:
                selectedPaymentSource = nil
                paymentMethodPreview = nil
                return nil
            }
        }
    }
}

extension CryptoOnrampCoordinator: STPApplePayContextDelegate {

    // MARK: - STPApplePayContextDelegate

    public func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        // Build a reasonable preview for the underlying Apple Pay payment method:
        let icon = STPImageLibrary.applePayCardImage()
        let label = String.Localized.apple_pay
        let sublabel: String? = {
            if let card = paymentMethod.card, let last4 = card.last4 {
                let brand = STPCard.string(from: card.brand)
                let formattedMessage = STPLocalizationUtils.localizedStripeString(
                    forKey: "%1$@ •••• %2$@",
                    bundleLocator: StripePaymentSheetBundleLocator.self
                )
                return String(format: formattedMessage, brand, last4)
            }
            return nil
        }()

        paymentMethodPreview = PaymentMethodPreview(
            icon: icon,
            label: label,
            sublabel: sublabel
        )

        selectedPaymentSource = .applePay(paymentMethod)

        completion(STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT, nil)
    }

    public func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Swift.Error?) {
        switch status {
        case .success:
            applePayCompletionContinuation?.resume(returning: .success)
        case .userCancellation:
            applePayCompletionContinuation?.resume(returning: .canceled)
        case .error:
            applePayCompletionContinuation?.resume(throwing: error ?? ApplePayPaymentStatus.Error.applePayFallbackError)
        @unknown default:
            applePayCompletionContinuation?.resume(throwing: error ?? ApplePayPaymentStatus.Error.applePayFallbackError)
        }

        applePayCompletionContinuation = nil
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

    @MainActor
    private func presentApplePay(using paymentRequest: PKPaymentRequest, from viewController: UIViewController) async throws -> ApplePayPaymentStatus {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ApplePayPaymentStatus, Swift.Error>) in
            guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) else {
                continuation.resume(throwing: ApplePayPaymentStatus.Error.applePayFallbackError)
                return
            }

            // Retain the continuation until we receive a completion delegate callback.
            self.applePayCompletionContinuation = continuation
            context.presentApplePay()
        }
    }
}
