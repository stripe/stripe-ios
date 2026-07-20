//
//  LinkController.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import Combine
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

/// A controller that presents the Link flow to collect and create a customer's payment method.
@MainActor @_spi(STP) @_spi(LinkControllerPreview) public class LinkController: ObservableObject {

    /// Represents the payment method currently selected by the user.
    @_spi(STP) @_spi(LinkControllerPreview) public struct PaymentMethodPreview {

        /// Represents the type of selected payment method.
        @_spi(STP) public enum PaymentMethodType {

            /// The user chose a card-based payment method, such as a debit or credit card.
            case card

            /// The user chose a bank account for payment.
            case bankAccount
        }

        /// The type of the selected payment method.
        @_spi(STP) public let paymentMethodType: PaymentMethodType

        /// The Link icon to render in your screen.
        @_spi(STP) @_spi(LinkControllerPreview) public let icon: UIImage

        /// The Link label to render in your screen.
        @_spi(STP) @_spi(LinkControllerPreview) public let label: String

        /// Details about the selected Link payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
        @_spi(STP) @_spi(LinkControllerPreview) public let sublabel: String?
    }

    @frozen @_spi(STP) public enum VerificationResult {
        /// Verification was completed successfully.
        case completed
        /// Verification was canceled by the user.
        case canceled
    }

    /// The result of presenting Link to collect a payment method.
    @frozen @_spi(STP) @_spi(LinkControllerPreview) public enum PaymentMethodResult {
        /// The user selected a payment method. The associated value is the resulting `STPPaymentMethod`.
        case completed(STPPaymentMethod)
        /// The user dismissed the flow without selecting a payment method.
        case canceled
    }

    @frozen @_spi(STP) public enum AuthorizationResult {
        /// Authorization was consented by the user.
        case consented
        /// Authorization was denied by the user.
        case denied
        /// The authorization flow was canceled by the user.
        case canceled
    }

    @frozen @_spi(STP) public enum UserAttestationResult {
        /// The user accepted the attestation.
        case confirmed
        /// The user dismissed the attestation without accepting.
        case canceled
    }

    /// Errors specific incorrect integrations with LinkController
    @_spi(STP) public enum IntegrationError: LocalizedError {
        case noPaymentMethodSelected
        case noActiveLinkConsumer
        case missingAppAttestation

        @_spi(STP) public var errorDescription: String? {
            switch self {
            case .noPaymentMethodSelected:
                return "No payment method has been selected."
            case .noActiveLinkConsumer:
                return "No active Link consumer is available."
            case .missingAppAttestation:
                return "App attestation is missing or device cannot use native Link."
            }
        }
    }

    /// The intent for which the `LinkController` collects a payment method.
    @_spi(STP) public enum Mode {
        case payment
        case paymentAndSetupFutureUse
        case setup
    }

    private let apiClient: STPAPIClient
    private let mode: Mode
    private let elementsSession: STPElementsSession
    private let intent: Intent
    private let paymentElementConfiguration: PaymentElementConfiguration
    private let initialLinkBrand: LinkBrand
    private let appearance: LinkAppearance?
    private let configuration: LinkConfiguration?
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private let requestSurface: LinkRequestSurface

    private lazy var linkAccountService: LinkAccountServiceProtocol = {
        LinkAccountService(apiClient: apiClient, elementsSession: elementsSession)
    }()

    private var selectedPaymentDetails: ConsumerPaymentDetails? {
        guard case .link(let confirmOption) = internalPaymentOption else {
            return nil
        }
        guard case .withPaymentDetails(_, _, let paymentDetails, _, _) = confirmOption else {
            return nil
        }
        return paymentDetails
    }

    private var internalPaymentOption: PaymentOption? {
        didSet {
            updatePaymentMethodPreview()
        }
    }

    private var lastCreatedPaymentMethod: STPPaymentMethod?

    /// Details on the current Link account.
    @Published @_spi(STP) public private(set) var linkAccount: PaymentSheetLinkAccount?

    /// A preview of the currently selected Link payment method.
    @Published @_spi(STP) @_spi(LinkControllerPreview) public private(set) var paymentMethodPreview: PaymentMethodPreview?

    private var resolvedLinkBrand: LinkBrand {
        linkAccount?.linkBrand ?? LinkAccountContext.shared.account?.linkBrand ?? initialLinkBrand
    }

    @_spi(STP) public var elementsSessionID: String {
        elementsSession.sessionID
    }

    /// Completion handler for full consent screen
    private var fullConsentCompletion: ((Result<AuthorizationResult, Error>) -> Void)?

    private init(
        apiClient: STPAPIClient = .shared,
        mode: Mode,
        elementsSession: STPElementsSession,
        intent: Intent,
        paymentElementConfiguration: PaymentElementConfiguration,
        linkBrand: LinkBrand,
        appearance: LinkAppearance?,
        configuration: LinkConfiguration?,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        requestSurface: LinkRequestSurface
    ) {
        self.apiClient = apiClient
        self.mode = mode
        self.elementsSession = elementsSession
        self.intent = intent
        self.paymentElementConfiguration = paymentElementConfiguration
        self.initialLinkBrand = linkBrand
        self.appearance = appearance
        self.configuration = configuration
        self.analyticsHelper = analyticsHelper
        self.requestSurface = requestSurface

        LinkAccountContext.shared.addObserver(self, selector: #selector(onLinkAccountChange))
    }

    deinit {
        // Just to make sure no observers stay around
        LinkAccountContext.shared.removeObserver(self)
    }

    @_spi(STP) public static var linkIcon: UIImage = Image.link_icon.makeImage()

    private func iconForPaymentDetails(_ paymentDetails: ConsumerPaymentDetails) -> UIImage {
        guard let appearance, appearance.reduceLinkBranding else {
            return Self.linkIcon
        }

        switch paymentDetails.details {
        case .card(let card):
            return STPImageLibrary.cardBrandImage(for: card.stpBrand)
        case .bankAccount(let bankAccount):
            let iconCode = PaymentSheetImageLibrary.bankIconCode(for: bankAccount.name)
            return PaymentSheetImageLibrary.bankIcon(for: iconCode, iconStyle: .filled)
        case .unparsable:
            return Self.linkIcon
        }
    }

    private func resolvedSupportedPaymentMethodTypes(
        override supportedPaymentMethodTypes: [LinkPaymentMethodType]?
    ) -> [LinkPaymentMethodType]? {
        Self.nonEmptySupportedPaymentMethodTypes(supportedPaymentMethodTypes)
            ?? Self.nonEmptySupportedPaymentMethodTypes(configuration?.supportedPaymentMethodTypes)
    }

    private static func nonEmptySupportedPaymentMethodTypes(
        _ supportedPaymentMethodTypes: [LinkPaymentMethodType]?
    ) -> [LinkPaymentMethodType]? {
        guard let supportedPaymentMethodTypes, !supportedPaymentMethodTypes.isEmpty else {
            return nil
        }
        return supportedPaymentMethodTypes
    }

    private func updatePaymentMethodPreview() {
        guard let selectedPaymentDetails else {
            paymentMethodPreview = nil
            return
        }

        let type: PaymentMethodPreview.PaymentMethodType = switch selectedPaymentDetails.details {
        case .card, .unparsable:
            .card
        case .bankAccount:
            .bankAccount
        }

        paymentMethodPreview = .init(
            paymentMethodType: type,
            icon: iconForPaymentDetails(selectedPaymentDetails),
            label: resolvedLinkBrand.displayName,
            sublabel: selectedPaymentDetails.linkPaymentDetailsFormattedString
        )
    }

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this controller. Defaults to `.shared`.
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Parameter appearance: Link UI-specific appearance overrides. If not specified, `PaymentSheet.Appearance` defaults are used.
    /// - Parameter linkConfiguration: Configuration for Link behavior and content. If not specified, default behavior is used.
    /// - Parameter requestSurface: The request surface to use for API calls. Defaults to `ios_payment_element`.
    /// - Parameter completion: A closure that is called with the result of the creation. It returns a `LinkController` if successful, or an error if the creation failed.
    @_spi(STP) public static func create(
        apiClient: STPAPIClient = .shared,
        mode: LinkController.Mode,
        appearance: LinkAppearance? = nil,
        linkConfiguration configuration: LinkConfiguration? = nil,
        requestSurface: LinkRequestSurface = .default,
        completion: @escaping (Result<LinkController, Error>) -> Void
    ) {
        Task {
            do {
                var paymentElementConfiguration = PaymentSheet.Configuration()
                paymentElementConfiguration.apiClient = apiClient
                if let appearance = appearance {
                    paymentElementConfiguration.style = appearance.style
                }
                if let merchantDisplayName = configuration?.merchantDisplayName {
                    paymentElementConfiguration.merchantDisplayName = merchantDisplayName
                }

                let analyticsHelper = PaymentSheetAnalyticsHelper(
                    integrationShape: .linkController,
                    configuration: paymentElementConfiguration
                )

                let loadResult = try await Self.loadElementsSession(
                    paymentElementConfiguration: paymentElementConfiguration,
                    linkConfiguration: configuration,
                    analyticsHelper: analyticsHelper
                )

                guard deviceCanUseNativeLink(
                    elementsSession: loadResult.elementsSession,
                    configuration: paymentElementConfiguration
                ) else {
                    completion(.failure(IntegrationError.missingAppAttestation))
                    return
                }

                let controller = LinkController(
                    apiClient: apiClient,
                    mode: mode,
                    elementsSession: loadResult.elementsSession,
                    intent: loadResult.intent,
                    paymentElementConfiguration: paymentElementConfiguration,
                    linkBrand: paymentElementConfiguration.resolvedLinkBrand(
                        elementsSession: loadResult.elementsSession,
                        linkAccount: LinkAccountContext.shared.account
                    ),
                    appearance: appearance,
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    requestSurface: requestSurface
                )
                completion(.success(controller))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Creates a `LinkController` for collecting a customer's payment method via Link.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance. Defaults to `.shared`.
    /// - Parameter appearance: Link UI appearance overrides.
    /// - Parameter configuration: Configuration for Link behaviour.
    /// - Parameter completion: Called with the ready `LinkController` or an error.
    @_spi(LinkControllerPreview) public static func create(
        apiClient: STPAPIClient = .shared,
        appearance: LinkAppearance? = nil,
        configuration: LinkConfiguration? = nil,
        completion: @escaping (Result<LinkController, Error>) -> Void
    ) {
        Task {
            do {
                var paymentElementConfiguration = PaymentSheet.Configuration()
                paymentElementConfiguration.apiClient = apiClient
                if let appearance = appearance {
                    paymentElementConfiguration.style = appearance.style
                }
                if let merchantDisplayName = configuration?.merchantDisplayName {
                    paymentElementConfiguration.merchantDisplayName = merchantDisplayName
                }

                let analyticsHelper = PaymentSheetAnalyticsHelper(
                    integrationShape: .linkController,
                    configuration: paymentElementConfiguration
                )

                let loadResult = try await Self.loadElementsSession(
                    paymentElementConfiguration: paymentElementConfiguration,
                    linkConfiguration: configuration,
                    analyticsHelper: analyticsHelper
                )

                guard deviceCanUseNativeLink(
                    elementsSession: loadResult.elementsSession,
                    configuration: paymentElementConfiguration
                ) else {
                    completion(.failure(IntegrationError.missingAppAttestation))
                    return
                }

                let controller = LinkController(
                    apiClient: apiClient,
                    mode: .setup,
                    elementsSession: loadResult.elementsSession,
                    intent: loadResult.intent,
                    paymentElementConfiguration: paymentElementConfiguration,
                    linkBrand: paymentElementConfiguration.resolvedLinkBrand(
                        elementsSession: loadResult.elementsSession,
                        linkAccount: LinkAccountContext.shared.account
                    ),
                    appearance: appearance,
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    requestSurface: .default
                )
                completion(.success(controller))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Looks up whether the provided email is associated with an existing Link consumer.
    ///
    /// - Parameter email: The email address to look up.
    /// - Parameter completion: A closure that is called with the result of the lookup. It returns `true` if the email is associated with a registered Link consumer, or `false` otherwise.
    @_spi(STP) public func lookupConsumer(with email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Self.lookupConsumer(
            email: email,
            linkAccountService: linkAccountService,
            requestSurface: requestSurface
        ) { result in
            switch result {
            case .success(let linkAccount):
                LinkAccountContext.shared.account = linkAccount
                completion(.success(linkAccount?.isRegistered ?? false))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Looks up the consumer using the provided auth token.
    ///
    /// - Parameter linkAuthTokenClientSecret: An encrypted one-time-use auth token that, upon successful call to this API, logs the Link user in without displaying UI for authentication / one time passcodes.
    /// - Parameter completion: A closure that is called when the lookup completes or fails.
    @_spi(STP) public func lookupLinkAuthToken(
        _ linkAuthTokenClientSecret: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Self.lookupLinkAuthToken(
            linkAuthTokenClientSecret,
            linkAccountService: linkAccountService,
            requestSurface: requestSurface
        ) { result in
            switch result {
            case .success(let linkAccount):
                LinkAccountContext.shared.account = linkAccount
                if linkAccount != nil {
                    completion(.success(()))
                } else {
                    completion(.failure(PaymentSheetError.linkLookupNotFound(serverErrorMessage: "")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Registers a new Link user with the provided details.
    /// `lookupConsumer` must be called before this.
    ///
    /// - Parameter fullName: The full name of the user.
    /// - Parameter phone: The phone number of the user. Expected to be in E.164 format.
    /// - Parameter country: The country code of the user.
    /// - Parameter consentAction: The action taken by the user in order to register for Link.
    /// - Parameter completion: A closure that is called with the result of the sign up.
    @_spi(STP) public func registerLinkUser(
        fullName: String?,
        phone: String,
        country: String,
        consentAction: PaymentSheetLinkAccount.ConsentAction,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let linkAccount else {
            let error = IntegrationError.noActiveLinkConsumer
            completion(.failure(error))
            return
        }
        linkAccount.signUp(
            with: phone,
            legalName: fullName,
            countryCode: country,
            consentAction: consentAction,
            completion: { [weak self] result in
                LinkAccountContext.shared.account = self?.linkAccount
                completion(result)
            }
        )
    }

    /// Presents the Link verification flow for an existing user which requires verification.
    /// `lookupConsumer` must be called before this.
    ///
    /// - Parameter viewController: The view controller from which to present the verification flow.
    /// - Parameter completion: A closure that is called with the result of the verification. It returns a `VerificationResult` if successful, or an error if the verification failed.
    @_spi(STP) public func presentForVerification(
        from viewController: UIViewController,
        completion: @escaping (Result<VerificationResult, Error>) -> Void
    ) {
        guard let linkAccount else {
            let error = IntegrationError.noActiveLinkConsumer
            completion(.failure(error))
            return
        }

        let verificationController = LinkVerificationController(
            mode: .inlineLogin,
            linkAccount: linkAccount,
            brand: resolvedLinkBrand,
            configuration: paymentElementConfiguration,
            appearance: appearance
        )

        verificationController.present(from: viewController) { result in
            switch result {
            case .completed:
                completion(.success(.completed))
            case .canceled, .switchAccount:
                completion(.success(.canceled))
            case .failed(let error):
                completion(.failure(error))
            }
        }
    }

    /// Presents the Link sheet to collect a customer's payment method.
    ///
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Parameter email: The email address to pre-fill in the Link sheet. If `nil`, the email field will be empty.
    /// - Parameter supportedPaymentMethodTypes: The payment method types to support in the Link sheet. If `nil` or empty, all available types are supported.
    /// - Parameter collectName: Whether or not we should collect the user's name and attach it to the billing details.
    /// - Parameter completion: A closure that is called when the user has selected a payment method or canceled the sheet. If the user selects a payment method, the `paymentMethodPreview` will be updated accordingly.
    @_spi(STP) public func collectPaymentMethod(
        from presentingViewController: UIViewController,
        with email: String?,
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        collectName: Bool = false,
        completion: @escaping (_ didSelectPaymentMethod: Bool) -> Void
    ) {
        var paymentElementConfiguration = self.paymentElementConfiguration
        paymentElementConfiguration.defaultBillingDetails.email = email

        if collectName {
            paymentElementConfiguration.billingDetailsCollectionConfiguration.name = .always
        }

        // TODO: We need a way to override Link's default primary button label, since we don't want to show "Pay $xx.xx" even for payment mode.
        print("Presenting Link wallet for \(mode)")

        presentingViewController.presentNativeLink(
            selectedPaymentDetailsID: selectedPaymentDetails?.stripeID,
            configuration: paymentElementConfiguration,
            intent: intent,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper,
            supportedPaymentMethodTypes: resolvedSupportedPaymentMethodTypes(
                override: supportedPaymentMethodTypes
            ),
            linkAppearance: appearance,
            linkConfiguration: configuration,
            canContinueWithoutLink: false
        ) { [weak self] confirmOption, shouldClearSelection in
            guard let confirmOption else {
                if shouldClearSelection {
                    self?.internalPaymentOption = nil
                }
                completion(false)
                return
            }

            self?.internalPaymentOption = .link(option: confirmOption)
            completion(true)
        }
    }

    /// Presents the full Link payment method selection flow, handling lookup, authentication or signup,
    /// wallet display, and payment method creation in a single call.
    ///
    /// Under the hood, this method:
    /// 1. Looks up the consumer by email, unless an authenticated session for that email already exists.
    /// 2. Presents the Link sheet, routing to signup, OTP verification, or the wallet based on account state.
    ///    If `phoneNumber` is provided, it is prefilled in the signup form.
    /// 3. Once the user selects a payment method, creates and returns an `STPPaymentMethod`.
    ///
    /// - Parameter email: The email address to look up and associate with the Link account.
    /// - Parameter phoneNumber: Optional phone number in E.164 format to prefill during signup.
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Parameter completion: A closure called with `.success(.completed(paymentMethod))` on selection,
    ///   `.success(.canceled)` if the user dismisses the flow, or `.failure(error)` on API or network errors.
    @_spi(STP) @_spi(LinkControllerPreview) public func present(
        email: String,
        phoneNumber: String? = nil,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        let alreadyAuthenticated = linkAccount?.sessionState == .verified
            && linkAccount?.email.lowercased() == email.lowercased()

        let presentWallet = { [weak self] in
            guard let self else { return }
            var paymentElementConfiguration = self.paymentElementConfiguration
            paymentElementConfiguration.defaultBillingDetails.email = email
            if let phoneNumber {
                paymentElementConfiguration.defaultBillingDetails.phone = phoneNumber
            }

            presentingViewController.presentNativeLink(
                selectedPaymentDetailsID: nil,
                configuration: paymentElementConfiguration,
                intent: self.intent,
                elementsSession: self.elementsSession,
                analyticsHelper: self.analyticsHelper,
                supportedPaymentMethodTypes: self.resolvedSupportedPaymentMethodTypes(override: nil),
                linkAppearance: self.appearance,
                linkConfiguration: self.configuration,
                canContinueWithoutLink: false
            ) { [weak self] confirmOption, _ in
                guard let self else { return }
                guard let confirmOption else {
                    completion(.success(.canceled))
                    return
                }
                self.internalPaymentOption = .link(option: confirmOption)
                self.createPaymentMethod { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let paymentMethod):
                        self.lastCreatedPaymentMethod = paymentMethod
                        completion(.success(.completed(paymentMethod)))
                    }
                }
            }
        }

        if alreadyAuthenticated {
            presentWallet()
        } else {
            lookupConsumer(with: email) { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success:
                    presentWallet()
                }
            }
        }
    }

    /// Confirms a SetupIntent using the payment method from the most recent `present()` call.
    ///
    /// Call this after a successful `.completed` result from `present(email:from:completion:)`.
    /// Provide a fresh SetupIntent client secret for each confirmation — reusing a consumed
    /// secret will fail.
    ///
    /// - Parameter clientSecret: The client secret of the SetupIntent to confirm.
    /// - Parameter presentingViewController: The view controller used as the authentication context
    ///   (e.g. for 3DS challenges).
    /// - Parameter completion: Called with `.completed(paymentMethod)` on success,
    ///   `.canceled` if the user cancels authentication, or an error.
    @_spi(LinkControllerPreview) public func confirmSetupIntent(
        clientSecret: String,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        guard let paymentMethod = lastCreatedPaymentMethod else {
            completion(.failure(IntegrationError.noPaymentMethodSelected))
            return
        }
        confirmSetupIntentInternal(
            clientSecret: clientSecret,
            paymentMethod: paymentMethod,
            from: presentingViewController,
            completion: completion
        )
    }

    /// Creates a [STPPaymentMethod] from the selected Link payment method preview.
    ///
    /// - Parameters:
    ///   - overridePublishableKey: Optional publishable key to use for the API request.
    ///   - completion: A closure that is called with the result of the payment method creation. It returns a `STPPaymentMethod` if successful, or an error if the payment method could not be created.
    @_spi(STP) public func createPaymentMethod(
        overridePublishableKey: String? = nil,
        completion: @escaping (Result<STPPaymentMethod, Error>) -> Void
    ) {
        guard let selectedPaymentDetails else {
            completion(.failure(IntegrationError.noPaymentMethodSelected))
            return
        }

        guard let linkAccount = LinkAccountContext.shared.account, let consumerSessionClientSecret = linkAccount.currentSession?.clientSecret else {
            completion(.failure(IntegrationError.noActiveLinkConsumer))
            return
        }

        if elementsSession.linkPassthroughModeEnabled {
            createPaymentMethodInPassthroughMode(
                paymentDetails: selectedPaymentDetails,
                consumerSessionClientSecret: consumerSessionClientSecret,
                overridePublishableKey: overridePublishableKey,
                completion: completion
            )
        } else {
            createPaymentMethodInPaymentMethodMode(
                paymentDetails: selectedPaymentDetails,
                linkAccount: linkAccount,
                overridePublishableKey: overridePublishableKey,
                completion: completion
            )
        }
    }

    /// Authorizes a Link auth intent, handling verification and OAuth consent flows as needed.
    ///
    /// This method will present verification if the account requires verification, and consent screens
    /// if consent is required.
    ///
    /// - Parameter linkAuthIntentId: The Link auth intent ID to authorize.
    /// - Parameter viewController: The view controller from which to present the authorization flow.
    /// - Returns: The result of the authorization. Either the user consented / rejected OAuth consent, or canceled the flow.
    ///   If authorization completes, a crypto customer ID will be included in the result.
    /// - Throws: An error if no Link account associated with the Link auth intent is found, or an API error occurs.
    @_spi(STP) public func authorize(
        linkAuthIntentId: String,
        from viewController: UIViewController,
        completion: @escaping (Result<AuthorizationResult, Error>) -> Void
    ) {
        linkAccountService.lookupLinkAuthIntent(
            linkAuthIntentID: linkAuthIntentId,
            requestSurface: requestSurface
        ) { [weak self] result in
            switch result {
            case .success(let response):
                if let response {
                    self?.linkAccount = response.linkAccount

                    // If verification is required, present verification flow
                    if !response.linkAccount.meetsMinimumAuthenticationLevel {
                        if case .inline = response.consentViewModel {
                            self?.presentVerificationWithConsent(
                                from: viewController,
                                consentViewModel: response.consentViewModel,
                                completion: completion
                            )
                            return
                        } else {
                            self?.presentForVerification(from: viewController, completion: { [weak self] result in
                                switch result {
                                case .success(let verificationResult):
                                    switch verificationResult {
                                    case .completed:
                                        // After verification, check for full consent
                                        self?.presentFullConsentIfNeeded(
                                            consentViewModel: response.consentViewModel,
                                            from: viewController,
                                            completion: completion
                                        )
                                    case .canceled:
                                        completion(.success(.canceled))
                                    }
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            })
                            return
                        }
                    }

                    // No verification required, check for full consent
                    self?.presentFullConsentIfNeeded(
                        consentViewModel: response.consentViewModel,
                        from: viewController,
                        completion: completion
                    )
                } else {
                    // No account found for this auth intent ID
                    completion(.failure(IntegrationError.noActiveLinkConsumer))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func presentFullConsentIfNeeded(
        consentViewModel: LinkConsentViewModel?,
        from viewController: UIViewController,
        completion: @escaping (Result<AuthorizationResult, Error>) -> Void
    ) {
        guard case .full(let fullConsentViewModel) = consentViewModel else {
            LinkAccountContext.shared.account = self.linkAccount
            completion(.success(.consented))
            return
        }
        presentFullConsentScreen(
            consentViewModel: fullConsentViewModel,
            from: viewController,
            completion: completion
        )
    }

    /// Updates the phone number for the current Link user.
    ///
    /// - Parameter phoneNumber: The phone number of the user. Phone number must be in E.164 format (e.g., +12125551234).
    /// Throws if an authenticated Link user is not available, phone number format is invalid, or an API error occurs.
    @_spi(STP) public func updatePhoneNumber(
        to phoneNumber: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let linkAccount = LinkAccountContext.shared.account, let consumerSessionClientSecret = linkAccount.currentSession?.clientSecret else {
            completion(.failure(IntegrationError.noActiveLinkConsumer))
            return
        }

        apiClient.updatePhoneNumber(
            consumerSessionClientSecret: consumerSessionClientSecret,
            phoneNumber: phoneNumber,
            requestSurface: requestSurface
        ) { [weak self] result in
            switch result {
            case .success(let consumerSession):
                self?.updateLinkAccount(with: consumerSession)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Presents KYC verification UI to the user.
    ///
    /// This method presents a bottom sheet displaying the provided KYC information for user review.
    /// The user can confirm the information, request to update their address, or cancel.
    ///
    /// - Parameters:
    ///   - info: The KYC information to display to the user.
    ///   - appearance: Appearance configuration for the verification UI.
    ///   - viewController: The view controller from which to present the verification flow.
    ///   - onConfirm: An async closure called when the user confirms. This is called *before* dismissal, allowing the caller to complete any async operations before the sheet is dismissed.
    /// - Returns: A `VerifyKYCResult` indicating whether the user confirmed, requested an address update, or canceled.
    /// Throws any error thrown by the `onConfirm` handler.
    @_spi(STP) public func presentKYCVerification(
        info: VerifyKYCInfo,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onConfirm: @escaping (() async throws -> Void)
    ) async throws -> VerifyKYCResult {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let verifyKYCViewController = VerifyKYCViewController(info: info, appearance: appearance)
                verifyKYCViewController.onResult = { [weak verifyKYCViewController] result in
                    verifyKYCViewController?.onResult = nil

                    // We'll report the result back to the caller after dismissal of the sheet.
                    let dismissAndResumeWithResult: (Result<VerifyKYCResult, Swift.Error>) -> Void = { continuationResult in
                        verifyKYCViewController?.dismiss(animated: true) {
                            continuation.resume(with: continuationResult)
                        }
                    }

                    switch result {
                    case .canceled, .updateAddress:
                        dismissAndResumeWithResult(.success(result))
                    case .confirmed:
                        Task {
                            do {
                                // Complete any async operation from the caller before dismissing.
                                try await onConfirm()
                                dismissAndResumeWithResult(.success(result))
                            } catch {
                                dismissAndResumeWithResult(.failure(error))
                            }
                        }
                    @unknown default:
                        dismissAndResumeWithResult(.success(result))
                    }
                }

                viewController.presentAsBottomSheet(verifyKYCViewController, appearance: .init())
            }
        }
    }

    /// Presents the user attestation to the user.
    ///
    /// This method presents a bottom sheet displaying the provided attestation HTML for user review.
    /// The user can confirm the attestation or cancel.
    ///
    /// - Parameters:
    ///   - html: The attestation HTML to display to the user.
    ///   - appearance: Appearance configuration for the attestation UI.
    ///   - viewController: The view controller from which to present the attestation flow.
    ///   - onConfirm: An async closure called when the user confirms. This is called *before* dismissal, allowing the caller to complete any async operations before the sheet is dismissed.
    /// - Returns: A `UserAttestationResult` indicating whether the user confirmed or canceled.
    /// Throws any error thrown by the `onConfirm` handler.
    @_spi(STP) public func presentUserAttestation(
        html: String,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onConfirm: @escaping (() async throws -> Void)
    ) async throws -> UserAttestationResult {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let attestationViewController = UserAttestationViewController(
                    html: html,
                    appearance: appearance,
                    brand: resolvedLinkBrand
                )
                attestationViewController.onResult = { [weak attestationViewController] result in
                    attestationViewController?.onResult = nil

                    let dismissAndResumeWithResult = { continuationResult in
                        attestationViewController?.dismiss(animated: true) {
                            continuation.resume(with: continuationResult)
                        }
                    }

                    switch result {
                    case .canceled:
                        dismissAndResumeWithResult(.success(result))
                    case .confirmed:
                        Task {
                            do {
                                try await onConfirm()
                                dismissAndResumeWithResult(.success(result))
                            } catch {
                                dismissAndResumeWithResult(.failure(error))
                            }
                        }
                    }
                }

                viewController.presentAsBottomSheet(attestationViewController, appearance: .init())
            }
        }
    }

    /// Logs out the current Link user, if any.
    @_spi(STP) public func logOut(completion: @escaping (Result<Void, Error>) -> Void) {
        func clearLinkAccountContextAndComplete() {
            LinkAccountContext.shared.account = nil
            completion(.success(()))
        }

        guard let session = linkAccount?.currentSession else {
            // If no Link account is available, treat this as a success.
            clearLinkAccountContextAndComplete()
            return
        }

        session.logout(
            requestSurface: requestSurface,
            completion: { result in
                switch result {
                case .success:
                    clearLinkAccountContextAndComplete()
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }

    // MARK: - Private methods

    private func confirmSetupIntentInternal(
        clientSecret: String,
        paymentMethod: STPPaymentMethod,
        from viewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        let confirmParams = STPSetupIntentConfirmParams(clientSecret: clientSecret)
        confirmParams.paymentMethodID = paymentMethod.stripeId

        // Required for off-session link PMs: captures consent given during the Link flow.
        let mandateData = STPMandateDataParams.makeWithInferredValues()
        confirmParams.mandateData = mandateData

        let authContext = ViewControllerAuthenticationContext(viewController: viewController)
        STPPaymentHandler.shared().confirmSetupIntent(
            params: confirmParams,
            authenticationContext: authContext
        ) { status, setupIntent, error in
            switch status {
            case .succeeded:
                let confirmedPM = setupIntent?.paymentMethod ?? paymentMethod
                completion(.success(.completed(confirmedPM)))
            case .canceled:
                completion(.success(.canceled))
            case .failed:
                completion(.failure(error ?? PaymentSheetError.unknown(debugDescription:
                    "SetupIntent confirmation failed without an error.")))
            @unknown default:
                completion(.failure(PaymentSheetError.unknown(debugDescription:
                    "Unexpected STPPaymentHandlerActionStatus.")))
            }
        }
    }

    private func updateLinkAccount(with consumerSession: ConsumerSession) {
        guard let linkAccount else {
            return
        }

        self.linkAccount = PaymentSheetLinkAccount(
            email: linkAccount.email,
            session: consumerSession,
            publishableKey: linkAccount.publishableKey,
            displayablePaymentDetails: linkAccount.displayablePaymentDetails,
            apiClient: linkAccount.apiClient,
            useMobileEndpoints: linkAccount.useMobileEndpoints,
            canSyncAttestationState: linkAccount.canSyncAttestationState,
            requestSurface: linkAccount.requestSurface
        )
    }

    private func presentVerificationWithConsent(
        from viewController: UIViewController,
        consentViewModel: LinkConsentViewModel?,
        completion: @escaping (Result<AuthorizationResult, Error>) -> Void
    ) {
        guard let linkAccount else {
            completion(.failure(IntegrationError.noActiveLinkConsumer))
            return
        }

        let verificationController = LinkVerificationController(
            mode: .inlineLogin,
            linkAccount: linkAccount,
            brand: resolvedLinkBrand,
            configuration: paymentElementConfiguration,
            appearance: appearance,
            consentViewModel: consentViewModel
        )

        verificationController.present(from: viewController) { [weak self] result in
            guard let self else { return }
            switch result {
            case .completed:
                LinkAccountContext.shared.account = self.linkAccount
                completion(.success(.consented))
            case .canceled, .switchAccount:
                completion(.success(.canceled))
            case .failed(let error):
                completion(.failure(error))
            }
        }
    }

    private func createPaymentMethodInPassthroughMode(
        paymentDetails: ConsumerPaymentDetails,
        consumerSessionClientSecret: String,
        overridePublishableKey: String?,
        completion: @escaping (Result<STPPaymentMethod, Error>) -> Void
    ) {
        // TODO: These parameters aren't final
        apiClient.sharePaymentDetails(
            for: consumerSessionClientSecret,
            id: paymentDetails.stripeID,
            overridePublishableKey: overridePublishableKey,
            allowRedisplay: nil,
            cvc: paymentDetails.cvc,
            expectedPaymentMethodType: nil,
            billingPhoneNumber: nil,
            clientAttributionMetadata: nil // LinkController is standalone and isn't a part of MPE, so it doesn't generate a client_session_id so we don't want to send CAM here
        ) { shareResult in
            switch shareResult {
            case .success(let success):
                completion(.success(success.paymentMethod))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }

    private func createPaymentMethodInPaymentMethodMode(
        paymentDetails: ConsumerPaymentDetails,
        linkAccount: PaymentSheetLinkAccount,
        overridePublishableKey: String?,
        completion: @escaping (Result<STPPaymentMethod, Error>) -> Void
    ) {
        Task {
            do {
                // TODO: These parameters aren't final
                let paymentMethodParams = linkAccount.makePaymentMethodParams(
                    from: paymentDetails,
                    cvc: paymentDetails.cvc,
                    billingPhoneNumber: nil,
                    allowRedisplay: nil
                )!

                let paymentMethod = try await apiClient.createPaymentMethod(
                    with: paymentMethodParams,
                    overridePublishableKey: overridePublishableKey
                )
                completion(.success(paymentMethod))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func loadElementsSession(
        paymentElementConfiguration: PaymentElementConfiguration,
        linkConfiguration: LinkConfiguration? = nil,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) async throws -> PaymentSheetLoader.LoadResult {
        // Stub path: no real intent, PM creation and confirmation handled externally.
        let intentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .setup(
                currency: nil,
                setupFutureUsage: .offSession
            ),
            paymentMethodTypes: linkConfiguration?.paymentMethodTypes,
            confirmHandler: { _, _ in
                stpAssertionFailure("The confirmHandler is not expected to be called in the LinkController.")
                return PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT
            }
        )
        let mode: PaymentSheet.InitializationMode = .deferredIntent(intentConfiguration)

        let (result, _) = try await PaymentSheetLoader.load(
            mode: mode,
            configuration: paymentElementConfiguration,
            analyticsHelper: analyticsHelper,
            // TODO: Add a non-logging integration shape or something
            integrationShape: .paymentSheet
        )

        return result
    }

    private static func lookupLinkAuthToken(
        _ linkAuthTokenClientSecret: String,
        linkAccountService: any LinkAccountServiceProtocol,
        requestSurface: LinkRequestSurface,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        linkAccountService.lookupLinkAuthToken(
            linkAuthTokenClientSecret,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    private static func lookupConsumer(
        email: String,
        linkAccountService: any LinkAccountServiceProtocol,
        requestSurface: LinkRequestSurface,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        linkAccountService.lookupAccount(
            withEmail: email,
            // TODO: Check that this is the right email source to pass in
            emailSource: .customerEmail,
            // TODO: Confirm which value to pass here to not cause experiment issues
            doNotLogConsumerFunnelEvent: false,
            requestSurface: requestSurface,
            completion: completion
        )
    }

    private func updateConsentStatus(
        consentGranted: Bool,
        completion: @escaping (Result<AuthorizationResult, Error>) -> Void
    ) {
        guard let linkAccount, let consumerSessionClientSecret = linkAccount.consumerSessionClientSecret else {
            completion(.failure(IntegrationError.noActiveLinkConsumer))
            return
        }

        apiClient.updateConsentStatus(
            consentGranted: consentGranted,
            consumerSessionClientSecret: consumerSessionClientSecret,
            consumerPublishableKey: linkAccount.publishableKey,
            completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    LinkAccountContext.shared.account = self.linkAccount
                    let result: AuthorizationResult = consentGranted ? .consented : .denied
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }

    @objc
    private func onLinkAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let linkAccount = notification.object as? PaymentSheetLinkAccount
            self?.linkAccount = linkAccount
            self?.updatePaymentMethodPreview()
        }
    }

    private func presentFullConsentScreen(
        consentViewModel: LinkConsentViewModel.FullConsentViewModel,
        from viewController: UIViewController,
        completion: @escaping (Result<AuthorizationResult, Error>) -> Void
    ) {
        let fullConsentViewController = LinkFullConsentViewController(
            consentViewModel: consentViewModel
        )

        fullConsentViewController.delegate = self

        let bottomSheetViewController = BottomSheetViewController(
            contentViewController: fullConsentViewController,
            appearance: paymentElementConfiguration.appearance,
            isTestMode: false,
            didCancelNative3DS2: {}
        )

        // Store completion handler for use in delegate method
        self.fullConsentCompletion = completion

        viewController.presentAsBottomSheet(
            bottomSheetViewController,
            appearance: paymentElementConfiguration.appearance
        )
    }
}

// MARK: - LinkFullConsentViewControllerDelegate

extension LinkController: LinkFullConsentViewControllerDelegate {
    func fullConsentViewController(
        _ controller: LinkFullConsentViewController,
        didFinishWithResult result: LinkController.AuthorizationResult
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self, let completion = self.fullConsentCompletion else { return }
            self.fullConsentCompletion = nil

            switch result {
            case .consented:
                updateConsentStatus(consentGranted: true, completion: completion)
            case .denied:
                updateConsentStatus(consentGranted: false, completion: completion)
            case .canceled:
                completion(.success(.canceled))
            }
        }
    }
}

@_spi(STP) public extension LinkController {

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this controller. Defaults to `.shared`.
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Parameter appearance: Link UI-specific appearance overrides. If not specified, `PaymentSheet.Configuration` defaults are used.
    /// - Parameter linkConfiguration: Configuration for Link behavior and content. If not specified, default behavior is used.
    /// - Parameter requestSurface: The request surface to use for API calls. Defaults to `ios_payment_element`.
    /// - Returns: A `LinkController` if successful, or throws an error if the creation failed.
    static func create(
        apiClient: STPAPIClient = .shared,
        mode: LinkController.Mode,
        appearance: LinkAppearance? = nil,
        linkConfiguration configuration: LinkConfiguration? = nil,
        requestSurface: LinkRequestSurface = .default
    ) async throws -> LinkController {
        return try await withCheckedThrowingContinuation { continuation in
            create(
                apiClient: apiClient,
                mode: mode,
                appearance: appearance,
                linkConfiguration: configuration,
                requestSurface: requestSurface
            ) { result in
                switch result {
                case .success(let controller):
                    continuation.resume(returning: controller)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Looks up whether the provided email is associated with an existing Link consumer.
    ///
    /// - Parameter email: The email address to look up.
    /// - Returns: Returns `true` if the email is associated with an existing Link consumer, or `false` otherwise.
    func lookupConsumer(with email: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            lookupConsumer(with: email) { result in
                switch result {
                case .success(let isExistingLinkConsumer):
                    continuation.resume(returning: isExistingLinkConsumer)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func lookupLinkAuthToken(_ linkAuthTokenClientSecret: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            lookupLinkAuthToken(linkAuthTokenClientSecret) { result in
                switch result {
                case .success(let isExistingLinkConsumer):
                    continuation.resume(returning: isExistingLinkConsumer)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Authorizes a Link auth intent, handling verification and consent flows as needed.
    ///
    /// This method will present verification if the account requires verification, and consent screens
    /// if consent is required. The flow adapts based on the auth intent configuration:
    /// - Inline consent: Presents verification with embedded consent
    /// - Full consent: Presents verification (if needed) followed by a dedicated consent screen
    /// - No consent: Presents verification only (if needed)
    ///
    /// - Parameter linkAuthIntentId: The Link auth intent ID to authorize.
    /// - Parameter viewController: The view controller from which to present the authorization flow.
    /// - Returns: The authorization result.
    func authorize(
        linkAuthIntentId: String,
        from viewController: UIViewController
    ) async throws -> AuthorizationResult {
        try await withCheckedThrowingContinuation { continuation in
            authorize(linkAuthIntentId: linkAuthIntentId, from: viewController) { result in
                switch result {
                case .success(let authorizeResult):
                    continuation.resume(returning: authorizeResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Registers a new Link user with the provided details.
    /// `lookupConsumer` must be called before this.
    ///
    /// - Parameter fullName: The full name of the user.
    /// - Parameter phone: The phone number of the user. Expected to be in E.164 format.
    /// - Parameter country: The country code of the user.
    /// - Parameter consentAction: The action taken by the user in order to register for Link.
    /// Throws if `lookupConsumer` was not called prior to this, or an API error occurs.
    func registerLinkUser(
        fullName: String?,
        phone: String,
        country: String,
        consentAction: PaymentSheetLinkAccount.ConsentAction
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            registerLinkUser(
                fullName: fullName,
                phone: phone,
                country: country,
                consentAction: consentAction
            ) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Presents the Link verification flow for an existing user.
    /// `lookupConsumer` must be called before this.
    ///
    /// - Parameter viewController: The view controller from which to present the verification flow.
    /// - Returns: A `AuthenticationResult` indicating whether verification was completed or canceled.
    /// Throws if `lookupConsumer` was not called prior to this, or an API error occurs.
    func presentForVerification(from viewController: UIViewController) async throws -> VerificationResult {
        try await withCheckedThrowingContinuation { continuation in
            presentForVerification(from: viewController) { result in
                switch result {
                case .success(let result):
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Presents the Link sheet to collect a customer's payment method.
    ///
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Parameter email: The email address to pre-fill in the Link sheet. If `nil`, the email field will be empty.
    /// - Parameter supportedPaymentMethodTypes: The payment method types to support in the Link sheet. If `nil` or empty, all available types are supported.
    /// - Parameter collectName: Whether or not we should collect the user's name and attach it to the billing details.
    /// - Returns: A `PaymentMethodDisplayData` if the user selected a payment method, or `nil` otherwise.
    func collectPaymentMethod(
        from presentingViewController: UIViewController,
        with email: String?,
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        collectName: Bool = false
    ) async -> LinkController.PaymentMethodPreview? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }
                self.collectPaymentMethod(
                    from: presentingViewController,
                    with: email,
                    supportedPaymentMethodTypes: supportedPaymentMethodTypes,
                    collectName: collectName
                ) { [weak self] didSelectPaymentMethod in
                    guard let self else { return }
                    continuation.resume(returning: didSelectPaymentMethod ? self.paymentMethodPreview : nil)
                }
            }
        }
    }

    /// Creates a [STPPaymentMethod] from the selected Link payment method preview.
    /// - Parameter overridePublishableKey: Optional publishable key to use for the API request.
    /// - Returns: A `STPPaymentMethod` if successful, or throws an error if the payment method could not be created.
    func createPaymentMethod(overridePublishableKey: String? = nil) async throws -> STPPaymentMethod {
        return try await withCheckedThrowingContinuation { continuation in
            createPaymentMethod(overridePublishableKey: overridePublishableKey) { result in
                switch result {
                case .success(let paymentMethod):
                    continuation.resume(returning: paymentMethod)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Updates the phone number for the current Link user.
    ///
    /// - Parameter phoneNumber: The phone number of the user. Phone number must be in E.164 format (e.g., +12125551234).
    /// Throws if an authenticated Link user is not available, phone number format is invalid, or an API error occurs.
    func updatePhoneNumber(to phoneNumber: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            updatePhoneNumber(to: phoneNumber) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Logs out the current Link user, if any.
    /// Throws if an API error occurs.
    func logOut() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            logOut { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@_spi(LinkControllerPreview) public extension LinkController {

    /// Creates a `LinkController` for collecting a customer's payment method via Link.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance. Defaults to `.shared`.
    /// - Parameter appearance: Link UI appearance overrides.
    /// - Parameter configuration: Configuration for Link behaviour.
    /// - Returns: A `LinkController` if successful, or throws an error if creation failed.
    static func create(
        apiClient: STPAPIClient = .shared,
        appearance: LinkAppearance? = nil,
        configuration: LinkConfiguration? = nil
    ) async throws -> LinkController {
        return try await withCheckedThrowingContinuation { continuation in
            create(
                apiClient: apiClient,
                appearance: appearance,
                configuration: configuration
            ) { result in
                switch result {
                case .success(let controller):
                    continuation.resume(returning: controller)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

}

@_spi(STP) @_spi(LinkControllerPreview) public extension LinkController {

    /// Presents the full Link payment method selection flow, handling lookup, authentication or signup,
    /// wallet display, and payment method creation in a single call.
    ///
    /// Under the hood, this method:
    /// 1. Looks up the consumer by email.
    /// 2. Presents the Link sheet, routing to signup, OTP verification, or the wallet based on account state.
    ///    If `phoneNumber` is provided, it is prefilled in the signup form.
    /// 3. Once the user selects a payment method, creates and returns an `STPPaymentMethod`.
    ///
    /// - Parameter email: The email address to look up and associate with the Link account.
    /// - Parameter phoneNumber: Optional phone number in E.164 format to prefill during signup.
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Returns: `.completed(paymentMethod)` on selection, or `.canceled` if the user dismisses the flow.
    /// - Throws: An error if the lookup fails or payment method creation fails.
    func present(
        email: String,
        phoneNumber: String? = nil,
        from presentingViewController: UIViewController
    ) async throws -> PaymentMethodResult {
        try await withCheckedThrowingContinuation { continuation in
            present(
                email: email,
                phoneNumber: phoneNumber,
                from: presentingViewController
            ) { result in
                switch result {
                case .success(let paymentMethodResult):
                    continuation.resume(returning: paymentMethodResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Confirms a SetupIntent using the payment method from the most recent `present()` call.
    ///
    /// - Parameter clientSecret: The client secret of the SetupIntent to confirm.
    /// - Parameter presentingViewController: The view controller used as the authentication context.
    /// - Returns: `.completed(paymentMethod)` on success, or `.canceled` if authentication is canceled.
    /// - Throws: An error if the confirmation fails or no payment method has been selected.
    func confirmSetupIntent(
        clientSecret: String,
        from presentingViewController: UIViewController
    ) async throws -> PaymentMethodResult {
        try await withCheckedThrowingContinuation { continuation in
            confirmSetupIntent(
                clientSecret: clientSecret,
                from: presentingViewController
            ) { result in
                switch result {
                case .success(let paymentMethodResult):
                    continuation.resume(returning: paymentMethodResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// Minimal STPAuthenticationContext wrapper used when confirming a SetupIntent
// with a plain UIViewController as the presenter.
private class ViewControllerAuthenticationContext: NSObject, STPAuthenticationContext {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func authenticationPresentingViewController() -> UIViewController {
        viewController ?? UIViewController()
    }
}
