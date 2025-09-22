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
    /// - Parameter cryptoCustomerID: The crypto customer's ID, if available.
    /// - Returns: A configured `CryptoOnrampCoordinator`.
    static func create(
        apiClient: STPAPIClient,
        appearance: LinkAppearance,
        cryptoCustomerID: String?
    ) async throws -> Self

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

    /// Updates the phone number for the current Link user.
    ///
    /// - Parameter phoneNumber: The phone number of the user. Phone number must be in E.164 format (e.g., +12125551234).
    /// Throws if an authenticated Link user is not available, phone number format is invalid, or an API error occurs.
    func updatePhoneNumber(to phoneNumber: String) async throws

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

    /// Logs out the current Link user, if any.
    /// Throws if an API error occurs.
    func logOut() async throws
}

/// Coordinates headless Link user authentication and identity verification, leaving most of the UI to the client.
@_spi(STP)
public final class CryptoOnrampCoordinator: NSObject, CryptoOnrampCoordinatorProtocol {

    private let linkController: LinkController
    private let apiClient: STPAPIClient
    private let appearance: LinkAppearance
    private let analyticsClient: CryptoOnrampAnalyticsClient
    private var applePayCompletionContinuation: CheckedContinuation<ApplePayPaymentStatus, Swift.Error>?
    private var selectedPaymentSource: SelectedPaymentSource?
    private var cryptoCustomerId: String?

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

    private init(
        linkController: LinkController,
        cryptoCustomerID: String?,
        apiClient: STPAPIClient = .shared,
        appearance: LinkAppearance,
        analyticsClient: CryptoOnrampAnalyticsClient
    ) {
        self.linkController = linkController
        self.cryptoCustomerId = cryptoCustomerID
        self.apiClient = apiClient
        self.appearance = appearance
        self.analyticsClient = analyticsClient
    }

    // MARK: - CryptoOnrampCoordinatorProtocol

    public static func create(
        apiClient: STPAPIClient = .shared,
        appearance: LinkAppearance = .init(),
        cryptoCustomerID: String? = nil
    ) async throws -> CryptoOnrampCoordinator {
        let analyticsClient = CryptoOnrampAnalyticsClient()

        do {
            let linkController = try await LinkController.create(
                apiClient: apiClient,
                mode: .payment,
                appearance: appearance,
                linkConfiguration: Self.linkConfiguration,
                requestSurface: .cryptoOnramp
            )

            let coordinator = CryptoOnrampCoordinator(
                linkController: linkController,
                cryptoCustomerID: cryptoCustomerID,
                apiClient: apiClient,
                appearance: appearance,
                analyticsClient: analyticsClient
            )

            analyticsClient.elementsSessionId = await linkController.elementsSessionID
            analyticsClient.log(.sessionCreated)
            return coordinator
        } catch {
            analyticsClient.log(.errorOccurred(during: .createSession, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func hasLinkAccount(with email: String) async throws -> Bool {
        do {
            let hasAccount = try await linkController.lookupConsumer(with: email)
            analyticsClient.log(.linkAccountLookupCompleted(hasLinkAccount: hasAccount))
            return hasAccount
        } catch {
            analyticsClient.log(.errorOccurred(during: .hasLinkAccount, errorMessage: error.localizedDescription))
            throw error
        }
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
                analyticsClient.log(.errorOccurred(during: .registerLinkUser, errorMessage: "Link account already exists"))
                throw Error.linkAccountAlreadyExists
            }
        } else {
            do {
                let hasExistingAccount = try await hasLinkAccount(with: email)
                if hasExistingAccount {
                    analyticsClient.log(.errorOccurred(during: .registerLinkUser, errorMessage: "Link account already exists"))
                    throw Error.linkAccountAlreadyExists
                }
            } catch {
                analyticsClient.log(.errorOccurred(during: .registerLinkUser, errorMessage: error.localizedDescription))
                throw error
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
            try handlePhoneFormatError(error, during: .registerLinkUser)
        }
        do {
            let customerId = try await apiClient.createCryptoCustomer(with: linkAccountInfo).id
            self.cryptoCustomerId = customerId
            analyticsClient.log(.linkRegistrationCompleted)
            return customerId
        } catch {
            analyticsClient.log(.errorOccurred(during: .registerLinkUser, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func updatePhoneNumber(to phoneNumber: String) async throws {
        do {
            try await linkController.updatePhoneNumber(to: phoneNumber)
            analyticsClient.log(.linkPhoneNumberUpdated)
        } catch {
            try handlePhoneFormatError(error, during: .updatePhoneNumber)
        }
    }

    public func authenticateUser(from viewController: UIViewController) async throws -> AuthenticationResult {
        analyticsClient.log(.linkUserAuthenticationStarted)
        do {
            let verificationResult = try await linkController.presentForVerification(from: viewController)
            switch verificationResult {
            case .canceled:
                return .canceled
            case .completed:
                do {
                    let customerId = try await apiClient.createCryptoCustomer(with: linkAccountInfo).id
                    self.cryptoCustomerId = customerId
                    analyticsClient.log(.linkUserAuthenticationCompleted)
                    return .completed(customerId: customerId)
                } catch {
                    analyticsClient.log(.errorOccurred(during: .authenticateUser, errorMessage: error.localizedDescription))
                    throw error
                }
            }
        } catch {
            analyticsClient.log(.errorOccurred(during: .authenticateUser, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func authorize(linkAuthIntentId: String, from viewController: UIViewController) async throws -> AuthorizationResult {
        analyticsClient.log(.linkAuthorizationStarted)
        do {
            let authorizeResult = try await linkController.authorize(linkAuthIntentId: linkAuthIntentId, from: viewController)
            switch authorizeResult {
            case .consented:
                do {
                    let customerId = try await apiClient.createCryptoCustomer(with: linkAccountInfo).id
                    self.cryptoCustomerId = customerId
                    analyticsClient.log(.linkAuthorizationCompleted(consented: true))
                    return .consented(customerId: customerId)
                } catch {
                    analyticsClient.log(.errorOccurred(during: .authorize, errorMessage: error.localizedDescription))
                    throw error
                }
            case .denied:
                analyticsClient.log(.linkAuthorizationCompleted(consented: false))
                return .denied
            case .canceled:
                return .canceled
            }
        } catch {
            analyticsClient.log(.errorOccurred(during: .authorize, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func attachKYCInfo(info: KycInfo) async throws {
        do {
            try await apiClient.collectKycInfo(info: info, linkAccountInfo: linkAccountInfo)
            analyticsClient.log(.kycInfoSubmitted)
        } catch {
            analyticsClient.log(.errorOccurred(during: .attachKycInfo, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func verifyIdentity(from viewController: UIViewController) async throws -> IdentityVerificationResult {
        analyticsClient.log(.identityVerificationStarted)
        do {
            let response = try await apiClient.startIdentityVerification(linkAccountInfo: linkAccountInfo)

            guard let ephemeralKey = response.ephemeralKey else {
                analyticsClient.log(.errorOccurred(during: .verifyIdentity, errorMessage: "Missing ephemeral key"))
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
                            self.analyticsClient.log(.identityVerificationCompleted)
                            continuation.resume(returning: IdentityVerificationResult.completed)
                        case .flowCanceled:
                            continuation.resume(returning: IdentityVerificationResult.canceled)
                        case .flowFailed(let error):
                            self.analyticsClient.log(.errorOccurred(during: .verifyIdentity, errorMessage: error.localizedDescription))
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        } catch {
            analyticsClient.log(.errorOccurred(during: .verifyIdentity, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func registerWalletAddress(walletAddress: String, network: CryptoNetwork) async throws {
        do {
            try await apiClient.collectWalletAddress(
                walletAddress: walletAddress,
                network: network,
                linkAccountInfo: linkAccountInfo
            )
            analyticsClient.log(.walletRegistered(network: network.rawValue))
        } catch {
            analyticsClient.log(.errorOccurred(during: .registerWalletAddress, errorMessage: error.localizedDescription))
            throw error
        }
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
            analyticsClient.log(.collectPaymentMethodCompleted(paymentMethodType: type.analyticsValue))
            return preview
        case .applePay(let paymentRequest):
            // This presents Apple Pay and fills `applePayPaymentMethod` + `paymentMethodPreview` in the delegate.
            do {
                let status = try await presentApplePay(using: paymentRequest, from: viewController)
                switch status {
                case .success:
                    guard case let .applePay(paymentMethod) = selectedPaymentSource else {
                        analyticsClient.log(.errorOccurred(during: .collectPaymentMethod, errorMessage: "No payment method selected"))
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

                    analyticsClient.log(.collectPaymentMethodCompleted(paymentMethodType: type.analyticsValue))
                    return paymentMethodPreview
                case .canceled:
                    selectedPaymentSource = nil
                    return nil
                }
            } catch {
                analyticsClient.log(.errorOccurred(during: .collectPaymentMethod, errorMessage: error.localizedDescription))
                throw error
            }
        }
    }

    public func createCryptoPaymentToken() async throws -> String {
        guard let selectedPaymentSource else {
            analyticsClient.log(.errorOccurred(during: .createCryptoPaymentToken, errorMessage: "No payment method selected"))
            throw Error.invalidSelectedPaymentSource
        }

        do {
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

            let token = try await apiClient.createPaymentToken(for: paymentMethodId)
            analyticsClient.log(.cryptoPaymentTokenCreated(paymentMethodType: selectedPaymentSource.analyticsValue))
            return token.id
        } catch {
            analyticsClient.log(.errorOccurred(during: .createCryptoPaymentToken, errorMessage: error.localizedDescription))
            throw error
        }
    }

    public func performCheckout(
        onrampSessionId: String,
        authenticationContext: STPAuthenticationContext,
        onrampSessionClientSecretProvider: @escaping (_ onrampSessionId: String) async throws -> String
    ) async throws -> CheckoutResult {
        guard let selectedPaymentSource else {
            throw Error.invalidSelectedPaymentSource
        }
        analyticsClient.log(.checkoutStarted(
            onrampSessionId: onrampSessionId,
            paymentMethodType: selectedPaymentSource.analyticsValue
        ))
        // First, attempt to check out and get the PaymentIntent
        let paymentIntent = try await performCheckoutAndRetrievePaymentIntent(
            onrampSessionId: onrampSessionId,
            onrampSessionClientSecretProvider: onrampSessionClientSecretProvider
        )

        // Check if the intent is already complete
        if let result = try mapIntentToCheckoutResult(paymentIntent) {
            if case .completed = result {
                analyticsClient.log(.checkoutCompleted(
                    onrampSessionId: onrampSessionId,
                    paymentMethodType: selectedPaymentSource.analyticsValue,
                    requiredAction: false
                ))
            }
            return result
        }

        // Handle any required next action (e.g., 3DS authentication)
        let handledIntentResult = try await handleNextAction(
            for: paymentIntent,
            with: authenticationContext
        )

        switch handledIntentResult {
        case .paymentIntent(let finalIntent):
            if finalIntent.checkoutResult?.success == true {
                // After successful next_action handling, attempt checkout again to complete the payment
                let finalPaymentIntent = try await performCheckoutAndRetrievePaymentIntent(
                    onrampSessionId: onrampSessionId,
                    onrampSessionClientSecretProvider: onrampSessionClientSecretProvider
                )

                // Map the final PaymentIntent status to a checkout result
                if let checkoutResult = try mapIntentToCheckoutResult(finalPaymentIntent) {
                    if case .completed = checkoutResult {
                        analyticsClient.log(.checkoutCompleted(
                            onrampSessionId: onrampSessionId,
                            paymentMethodType: selectedPaymentSource.analyticsValue,
                            requiredAction: true
                        ))
                    }
                    return checkoutResult
                } else {
                    throw CheckoutError.paymentFailed
                }
            } else {
                analyticsClient.log(.errorOccurred(during: .performCheckout, errorMessage: "Payment failed"))
                throw CheckoutError.paymentFailed
            }
        case .canceled:
            return .canceled
        }
    }

    public func logOut() async throws {
        do {
            try await linkController.logOut()
            analyticsClient.log(.userLoggedOut)
        } catch {
            analyticsClient.log(.errorOccurred(during: .logOut, errorMessage: error.localizedDescription))
            throw error
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

        guard let cryptoCustomerId else {
            throw Error.missingCryptoCustomerID
        }

        // Fetch platform settings and create API client
        let platformSettings = try await apiClient.getPlatformSettings(cryptoCustomerId: cryptoCustomerId)
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
        return try intent.checkoutResult?.get()
    }

    func handlePhoneFormatError(_ error: Swift.Error, during operation: CryptoOnrampOperation) throws {
        if let stripeError = (error as? StripeError),
           case let .apiError(stripeAPIError) = stripeError,
           stripeAPIError.type == .invalidRequestError,
           let message = stripeAPIError.message,
           message.hasPrefix("There was an issue parsing the phone number") {
            analyticsClient.log(.errorOccurred(during: operation, errorMessage: "Invalid phone number format"))
            throw Error.invalidPhoneFormat
        } else {
            analyticsClient.log(.errorOccurred(during: operation, errorMessage: error.localizedDescription))
            throw error
        }
    }
}

private extension STPPaymentIntent {
    var checkoutResult: Result<CheckoutResult, CheckoutError>? {
        switch status {
        case .succeeded, .requiresCapture:
            return .success(.completed)
        case .processing:
            return paymentMethod?.type == .USBankAccount ? .success(.completed) : .failure(.paymentFailed)
        case .requiresPaymentMethod:
            return .failure(.paymentFailed)
        case .requiresAction:
            return nil
        default:
            return .failure(.paymentFailed)
        }
    }
}
