//
//  CryptoOnrampCoordinator.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 7/14/25.
//

import Foundation
import PassKit

@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripeIdentity
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

import UIKit

/// A coordinator that facilitates the crypto onramp process including user authentication, identity verification, payment collection, and checkouts.
protocol CryptoOnrampCoordinatorProtocol {

    /// Creates a `CryptoOnrampCoordinator` to facilitate authentication, identity verification, payment collection, and checkouts.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this coordinator. Defaults to `.shared`.
    /// - Parameter appearance: Customizable appearance-related configuration for any Stripe-provided UI.
    /// - Returns: A configured `CryptoOnrampCoordinator`.
    static func create(apiClient: STPAPIClient, appearance: LinkAppearance) async throws -> Self

    /// Whether or not the provided email is associated with an existing Link consumer.
    ///
    /// - Parameter email: The email address to look up.
    /// - Returns: Returns `true` if the email is associated with an existing Link consumer, or `false` otherwise.
    func hasLinkAccount(with email: String) async throws -> Bool

    /// Registers a new Link user with the provided details.
    ///
    /// - Parameter email: The user's email to be used for signup.
    /// - Parameter fullName: The full name of the user. A name should be collected if the user is located outside of the US, otherwise it is optional.
    /// - Parameter phone: The phone number of the user. Phone number must be in E.164 format (e.g., +12125551234), otherwise an error will be thrown.
    /// - Parameter country: The two-letter country code of the user (ISO 3166-1 alpha-2).
    /// - Returns: The crypto customer ID.
    /// Throws if email is already associated with a Link user, or an API error occurs.
    @discardableResult
    func registerLinkUser(
        email: String,
        fullName: String?,
        phone: String,
        country: String
    ) async throws -> String

    /// Presents Link UI to authenticate an existing Link user.
    /// `hasLinkAccount` must be called before this.
    ///
    /// - Parameter viewController: The view controller from which to present the authentication flow.
    /// - Returns: A `AuthenticationResult` indicating whether authentication was completed or canceled.
    ///   If authentication completes, a crypto customer ID will be included in the result.
    /// Throws if `hasLinkAccount` was not called prior to this, or an API error occurs after the view controller is presented.
    func authenticateUser(from viewController: UIViewController) async throws -> AuthenticationResult

    /// Authorizes a Link auth intent and authenticates the user if necessary.
    /// - Parameters:
    ///   - linkAuthIntentId: The Link auth intent ID to authorize.
    ///   - viewController: The view controller from which to present the authentication flow.
    /// - Returns: The result of the authorization.
    func authorize(linkAuthIntentId: String, from viewController: UIViewController) async throws -> AuthorizationResult

    /// Attaches the specific KYC info to the current Link user. Requires an authenticated Link user.
    ///
    /// - Parameter info: The KYC info to attach to the Link user.
    /// Throws if an authenticated Link user is not available, or an API error occurs.
    func attachKYCInfo(info: KycInfo) async throws

    /// Creates an identity verification session and launches the document verification flow.
    /// Requires an authenticated Link user.
    ///
    /// - Parameter viewController: The view controller from which to present the document verification flow.
    /// - Returns: An `IdentityVerificationResult` representing the outcome of the document verification process.
    /// Throws if an authenticated Link user is not available, or an API error occurs.
    func verifyIdentity(from viewController: UIViewController) async throws -> IdentityVerificationResult

    /// Registers the given crypto wallet address to the current Link account.
    /// Requires an authenticated Link user.
    ///
    /// - Parameter walletAddress: The crypto wallet address to register.
    /// - Parameter network: The crypto network for the wallet address.
    /// Throws if an authenticated Link user is not available, or an API error occurs.
    func registerWalletAddress(walletAddress: String, network: CryptoNetwork) async throws

    /// Presents UI to collect/select a payment method of the given type.
    ///
    /// - Parameters:
    ///   - type: The payment method type to collect. For `.card` and `.bankAccount`, this presents Link. For `.applePay(paymentRequest:)`, this presents Apple Pay using the provided `PKPaymentRequest`.
    ///   - viewController: The view controller from which to present the UI.
    /// - Returns: A `PaymentMethodDisplayData` describing the user’s selection, or `nil` if the user cancels.
    /// Throws an error if presentation or payment method collection fails.
    @MainActor
    func collectPaymentMethod(type: PaymentMethodType, from viewController: UIViewController) async throws -> PaymentMethodDisplayData?

    /// Creates a crypto payment token for the payment method currently selected on the coordinator.
    /// Call after a successful `collectPaymentMethod(...)`.
    ///
    /// - Returns: The crypto payment token ID.
    /// Throws an error if no payment method has been selected, the Link account is not verified, required session credentials are missing, the payment method creation fails, or a network/API error occurs.
    func createCryptoPaymentToken() async throws -> String

    /// Performs the checkout flow for a crypto onramp session, handling any required authentication steps.
    /// - Parameters:
    ///   - onrampSessionId: The onramp session identifier.
    ///   - authenticationContext: The authentication context used to handle any required next actions (e.g., 3DS authentication).
    ///   - onrampSessionClientSecretProvider: An async closure that calls your backend to perform a checkout.
    ///     Your backend should call Stripe's `/v1/crypto/onramp_sessions/:id/checkout` endpoint with the provided onramp session ID.
    ///     The closure should return the onramp session client secret on success, or throw an Error on failure.
    ///     This closure may be called twice: once initially, and once more after handling any required authentication.
    /// - Returns: A `CheckoutResult` indicating whether the checkout succeeded or was canceled.
    /// Throws if handling required actions fails, or an API error occurs.
    func performCheckout(
        onrampSessionId: String,
        authenticationContext: STPAuthenticationContext,
        onrampSessionClientSecretProvider: @escaping (_ onrampSessionId: String) async throws -> String
    ) async throws -> CheckoutResult
}

/// Coordinates headless Link user authentication and identity verification, leaving most of the UI to the client.
@_spi(STP)
public final class CryptoOnrampCoordinator: NSObject, CryptoOnrampCoordinatorProtocol {

    /// A subset of errors that may be thrown by `CryptoOnrampCoordinator` APIs.
    public enum Error: Swift.Error {

        /// Phone number validation failed. Phone number should be in E.164 format (e.g., +12125551234).
        case invalidPhoneFormat

        /// A Link account already exists for the provided email address.
        case linkAccountAlreadyExists

        /// `ephemeralKey` is missing from the response after starting identity verification.
        case missingEphemeralKey

        /// An unexpected error occurred internally. `selectedPaymentSource` was not set to an expected value.
        case invalidSelectedPaymentSource
    }

    private let linkController: LinkController
    private let apiClient: STPAPIClient
    private let appearance: LinkAppearance
    private var applePayCompletionContinuation: CheckedContinuation<ApplePayPaymentStatus, Swift.Error>?
    private var selectedPaymentSource: SelectedPaymentSource?

    /// Dedicated API client configured with the platform publishable key
    private var platformApiClient: STPAPIClient?

    private var linkAccountInfo: PaymentSheetLinkAccountInfoProtocol {
        get async throws {
            guard let linkAccount = await linkController.linkAccount else {
                throw LinkController.IntegrationError.noActiveLinkConsumer
            }
            return linkAccount
        }
    }

    private static let linkConfiguration: LinkConfiguration = LinkConfiguration(
        hintMessage: String.Localized.debitIsMostLikelyToBeAccepted,
        allowLogout: false
    )

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
            linkConfiguration: Self.linkConfiguration,
            requestSurface: .cryptoOnramp
        )

        return CryptoOnrampCoordinator(
            linkController: linkController,
            apiClient: apiClient,
            appearance: appearance
        )
    }

    public func hasLinkAccount(with email: String) async throws -> Bool {
        return try await linkController.lookupConsumer(with: email)
    }

    @discardableResult
    public func registerLinkUser(
        email: String,
        fullName: String?,
        phone: String,
        country: String
    ) async throws -> String {
        // Short-circuit if a registered Link account is already available,
        // or a Link account already exists for the provided email.
        if let linkAccount = await linkController.linkAccount {
            if linkAccount.isRegistered {
                throw Error.linkAccountAlreadyExists
            }
        } else {
            let hasExistingAccount = try await hasLinkAccount(with: email)
            if hasExistingAccount {
                throw Error.linkAccountAlreadyExists
            }
        }

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

    public func authenticateUser(from viewController: UIViewController) async throws -> AuthenticationResult {
        let verificationResult = try await linkController.presentForVerification(from: viewController)
        switch verificationResult {
        case .canceled:
            return .canceled
        case .completed:
            let customerId = try await apiClient.grantPartnerMerchantPermissions(with: linkAccountInfo).id
            return .completed(customerId: customerId)
        }
    }

    public func authorize(linkAuthIntentId: String, from viewController: UIViewController) async throws -> AuthorizationResult {
        let authorizeResult = try await linkController.authorize(linkAuthIntentId: linkAuthIntentId, from: viewController)
        switch authorizeResult {
        case .consented:
            let customerId = try await apiClient.grantPartnerMerchantPermissions(with: linkAccountInfo).id
            return .consented(customerId: customerId)
        case .denied: return .denied
        case .canceled: return .canceled
        }
    }

    public func attachKYCInfo(info: KycInfo) async throws {
        try await apiClient.collectKycInfo(info: info, linkAccountInfo: linkAccountInfo)
    }

    public func verifyIdentity(from viewController: UIViewController) async throws -> IdentityVerificationResult {
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

    public func registerWalletAddress(walletAddress: String, network: CryptoNetwork) async throws {
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
    ) async throws -> PaymentMethodDisplayData? {
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
                return nil
            }

            let preview = PaymentMethodDisplayData(
                icon: result.icon,
                label: result.label,
                sublabel: result.sublabel
            )
            selectedPaymentSource = .link
            return preview
        case .applePay(let paymentRequest):
            // This presents Apple Pay and fills `applePayPaymentMethod` + `paymentMethodPreview` in the delegate.
            let status = try await presentApplePay(using: paymentRequest, from: viewController)
            switch status {
            case .success:
                guard case let .applePay(paymentMethod) = selectedPaymentSource else {
                    throw Error.invalidSelectedPaymentSource
                }

                // Build a reasonable preview for the underlying Apple Pay payment method:
                let icon = STPImageLibrary.applePayCardImage()
                let label = String.Localized.apple_pay
                let sublabel: String? = {
                    if let card = paymentMethod.card {
                        return String.Localized.redactedCardDetails(using: card)
                    } else {
                        return nil
                    }
                }()

                let paymentMethodPreview = PaymentMethodDisplayData(
                    icon: icon,
                    label: label,
                    sublabel: sublabel
                )

                return paymentMethodPreview
            case .canceled:
                selectedPaymentSource = nil
                return nil
            }
        }
    }

    public func createCryptoPaymentToken() async throws -> String {
        guard let selectedPaymentSource else {
            throw Error.invalidSelectedPaymentSource
        }

        let paymentMethodId: String = try await {
            switch selectedPaymentSource {
            case .link:
                let platformApiClient = try await getPlatformApiClient()
                let paymentMethod = try await linkController.createPaymentMethod(
                    overridePublishableKey: platformApiClient.publishableKey
                )
                return paymentMethod.stripeId
            case .applePay(let paymentMethod):
                return paymentMethod.id
            }
        }()

        let token = try await apiClient.createPaymentToken(
            for: paymentMethodId,
            linkAccountInfo: linkAccountInfo
        )
        return token.id
    }

    public func performCheckout(
        onrampSessionId: String,
        authenticationContext: STPAuthenticationContext,
        onrampSessionClientSecretProvider: @escaping (_ onrampSessionId: String) async throws -> String
    ) async throws -> CheckoutResult {
        // First, attempt to check out and get the PaymentIntent
        let paymentIntent = try await performCheckoutAndRetrievePaymentIntent(
            onrampSessionId: onrampSessionId,
            onrampSessionClientSecretProvider: onrampSessionClientSecretProvider
        )

        // Check if the intent is already complete
        if let result = try mapIntentToCheckoutResult(paymentIntent) {
            return result
        }

        // Handle any required next action (e.g., 3DS authentication)
        let handledIntentResult = try await handleNextAction(
            for: paymentIntent,
            with: authenticationContext
        )

        switch handledIntentResult {
        case .paymentIntent(let finalIntent):
            if finalIntent.status == .succeeded || finalIntent.status == .requiresCapture {
                // After successful next_action handling, attempt checkout again to complete the payment
                let finalPaymentIntent = try await performCheckoutAndRetrievePaymentIntent(
                    onrampSessionId: onrampSessionId,
                    onrampSessionClientSecretProvider: onrampSessionClientSecretProvider
                )

                // Map the final PaymentIntent status to a checkout result
                if let checkoutResult = try mapIntentToCheckoutResult(finalPaymentIntent) {
                    return checkoutResult
                } else {
                    throw CheckoutError.paymentFailed
                }
            } else {
                throw CheckoutError.paymentFailed
            }
        case .canceled:
            return .canceled
        }
    }
}

extension CryptoOnrampCoordinator: ApplePayContextDelegate {

    // MARK: - ApplePayContextDelegate

    public func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        selectedPaymentSource = .applePay(paymentMethod)

        completion(STPApplePayContext.COMPLETE_WITHOUT_CONFIRMING_INTENT, nil)
    }

    public func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPApplePayContext.PaymentStatus, error: Swift.Error?) {
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

/// Possible results from `handleNextAction()`.
private enum NextActionResult {
    case paymentIntent(STPPaymentIntent)
    case canceled
}

private extension CryptoOnrampCoordinator {
    func fetchMerchantImageWithFallback() async -> UIImage {
        guard let merchantLogoUrl = await linkController.merchantLogoUrl else {
            return Image.wallet.makeImage()
        }

        do {
            return try await DownloadManager.sharedManager.downloadImage(url: merchantLogoUrl)
        } catch {
            return Image.wallet.makeImage()
        }
    }

    @MainActor
    func presentApplePay(using paymentRequest: PKPaymentRequest, from viewController: UIViewController) async throws -> ApplePayPaymentStatus {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ApplePayPaymentStatus, Swift.Error>) in
            guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) else {
                continuation.resume(throwing: ApplePayPaymentStatus.Error.applePayFallbackError)
                return
            }

            Task {
                do {
                    // Configure Apple Pay context to use platform API client
                    let platformApiClient = try await getPlatformApiClient()
                    context.apiClient = platformApiClient

                    // Retain the continuation until we receive a completion delegate callback.
                    self.applePayCompletionContinuation = continuation
                    context.presentApplePay()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Handles the next action for an `STPPaymentIntent` using `STPPaymentHandler`.
    func handleNextAction(
        for intent: STPPaymentIntent,
        with authenticationContext: STPAuthenticationContext
    ) async throws -> NextActionResult {
        let platformApiClient = try await getPlatformApiClient()
        let paymentHandler = STPPaymentHandler(apiClient: platformApiClient)

        return try await withCheckedThrowingContinuation { continuation in
            paymentHandler.handleNextAction(
                for: intent,
                with: authenticationContext,
                returnURL: nil,
                shouldSendAnalytic: true
            ) { status, paymentIntent, error in
                switch status {
                case .succeeded:
                    if let paymentIntent {
                        continuation.resume(returning: .paymentIntent(paymentIntent))
                    } else {
                        continuation.resume(throwing: CheckoutError.unexpectedError)
                    }
                case .canceled:
                    continuation.resume(returning: .canceled)
                case .failed:
                    continuation.resume(throwing: error ?? CheckoutError.paymentFailed)
                @unknown default:
                    continuation.resume(throwing: CheckoutError.unexpectedError)
                }
            }
        }
    }

    /// Returns a dedicated API client configured with the platform publishable key.
    /// Caches the API client after first creation to avoid repeated API calls.
    private func getPlatformApiClient() async throws -> STPAPIClient {
        if let platformApiClient {
            return platformApiClient
        }

        // Fetch platform settings and create API client
        let platformSettings = try await apiClient.getPlatformSettings(linkAccountInfo: linkAccountInfo)
        let newPlatformApiClient = STPAPIClient(publishableKey: platformSettings.publishableKey)
        platformApiClient = newPlatformApiClient
        return newPlatformApiClient
    }

    /// Performs checkout and retrieves the resulting PaymentIntent.
    private func performCheckoutAndRetrievePaymentIntent(
        onrampSessionId: String,
        onrampSessionClientSecretProvider: @escaping (_ onrampSessionId: String) async throws -> String
    ) async throws -> STPPaymentIntent {
        let onrampSessionClientSecret = try await onrampSessionClientSecretProvider(onrampSessionId)

        // Get the onramp session to extract the payment_intent_client_secret
        let onrampSession = try await apiClient.getOnrampSession(
            sessionId: onrampSessionId,
            sessionClientSecret: onrampSessionClientSecret
        )

        // Retrieve and return the PaymentIntent
        return try await retrievePaymentIntent(withClientSecret: onrampSession.paymentIntentClientSecret)
    }

    /// Retrieves a PaymentIntent using the provided client secret.
    private func retrievePaymentIntent(withClientSecret clientSecret: String) async throws -> STPPaymentIntent {
        let platformApiClient = try await getPlatformApiClient()

        return try await withCheckedThrowingContinuation { continuation in
            platformApiClient.retrievePaymentIntent(
                withClientSecret: clientSecret,
                expand: ["payment_method"]
            ) { paymentIntent, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let paymentIntent = paymentIntent {
                    continuation.resume(returning: paymentIntent)
                } else {
                    continuation.resume(throwing: CheckoutError.unexpectedError)
                }
            }
        }
    }

    /// Maps a PaymentIntent status to a CheckoutResult, or returns nil if more handling is needed.
    func mapIntentToCheckoutResult(_ intent: STPPaymentIntent) throws -> CheckoutResult? {
        switch intent.status {
        case .succeeded:
            return .completed
        case .requiresPaymentMethod:
            throw CheckoutError.paymentFailed
        case .requiresAction:
            return nil
        default:
            throw CheckoutError.paymentFailed
        }
    }
}
