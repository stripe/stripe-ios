//
//  LinkController.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import Combine
import UIKit

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore

/// A controller that presents the Link flow to collect and create a customer's payment method.
@MainActor @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public class LinkController: ObservableObject {

    /// Represents the payment method currently selected by the user.
    @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public struct PaymentMethodPreview {

        /// Represents the type of selected payment method.
        @_spi(InternalOnlyAPI) public enum PaymentMethodType {

            /// The user chose a card-based payment method, such as a debit or credit card.
            case card

            /// The user chose a bank account for payment.
            case bankAccount
        }

        /// The type of the selected payment method.
        @_spi(InternalOnlyAPI) public let paymentMethodType: PaymentMethodType

        /// The Link icon to render in your screen.
        @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public let icon: UIImage

        /// The Link label to render in your screen.
        @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public let label: String

        /// Details about the selected Link payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
        @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public let sublabel: String?
    }

    @frozen @_spi(InternalOnlyAPI) public enum VerificationResult {
        /// Verification was completed successfully.
        case completed
        /// Verification was canceled by the user.
        case canceled
    }

    /// The result of presenting Link.
    @frozen @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public enum PaymentMethodResult {
        /// The customer selected a payment method, and you complete the payment or setup.
        /// Returned when the `LinkController` was created without an `IntentConfiguration`.
        case completed(STPPaymentMethod)
        /// Link confirmed the PaymentIntent or SetupIntent with this payment method.
        /// Returned when the `LinkController` was created with an `IntentConfiguration`.
        case confirmed(STPPaymentMethod)
        /// The user dismissed the flow before it completed.
        case canceled

        /// The customer's payment method, if the flow completed.
        var paymentMethod: STPPaymentMethod? {
            switch self {
            case .completed(let paymentMethod), .confirmed(let paymentMethod):
                return paymentMethod
            case .canceled:
                return nil
            }
        }
    }

    @frozen @_spi(InternalOnlyAPI) public enum AuthorizationResult {
        /// Authorization was consented by the user.
        case consented
        /// Authorization was denied by the user.
        case denied
        /// The authorization flow was canceled by the user.
        case canceled
    }

    @frozen @_spi(InternalOnlyAPI) public enum UserAttestationResult {
        /// The user accepted the attestation.
        case confirmed
        /// The user dismissed the attestation without accepting.
        case canceled
    }

    @frozen @_spi(InternalOnlyAPI) public enum PartnerTermsResult {
        /// The user accepted the partner terms.
        case accepted
        /// The user dismissed the partner terms without accepting.
        case canceled
    }

    /// Errors specific incorrect integrations with LinkController
    /// Errors caused by how `LinkController` is integrated or configured.
    @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public enum IntegrationError: LocalizedError {
        /// `confirmSetupIntent` was called before the customer selected a payment method.
        case noPaymentMethodSelected
        /// The operation requires a signed-in Link consumer.
        case noActiveLinkConsumer
        /// The device or app can't use native Link, e.g. because app attestation isn't available.
        case missingAppAttestation
        /// Link isn't enabled for this merchant.
        case linkUnavailable
        /// Native Link isn't available on this device, and the Link web flow can't satisfy the `LinkConfiguration`:
        /// it can't collect billing details (`billingDetailsCollectionConfiguration`) or limit the payment method
        /// types (`supportedPaymentMethodTypes`).
        case configurationRequiresNativeLink
        /// The client secret from a `LinkWalletButtonViewModel.Mode`'s `clientSecretProvider` is for a different kind of
        /// intent than the mode, e.g. a SetupIntent's client secret for `.payment`.
        case intentMismatch

        public var errorDescription: String? {
            switch self {
            case .noPaymentMethodSelected:
                return "No payment method has been selected."
            case .noActiveLinkConsumer:
                return "No active Link consumer is available."
            case .missingAppAttestation:
                return "App attestation is missing or device cannot use native Link."
            case .linkUnavailable:
                return "Link is not available for this merchant. Check that Link is enabled in your Payment Element settings."
            case .configurationRequiresNativeLink:
                return "Native Link isn't available on this device, and the Link web flow can't collect billing details or limit the supported payment method types. Remove billingDetailsCollectionConfiguration and supportedPaymentMethodTypes from the LinkConfiguration to use the Link web flow."
            case .intentMismatch:
                return "The client secret returned by clientSecretProvider is for a different kind of intent than the LinkWalletButtonViewModel.Mode: return a PaymentIntent's client secret for .payment, and a SetupIntent's for .setup."
            }
        }
    }

    /// The intent for which the `LinkController` collects a payment method.
    @_spi(InternalOnlyAPI) public enum Mode {
        case payment
        case paymentAndSetupFutureUse
        case setup

        init(_ intentMode: PaymentSheet.IntentConfiguration.Mode) {
            switch intentMode {
            case let .payment(_, _, setupFutureUsage, _, _):
                self = setupFutureUsage == nil ? .payment : .paymentAndSetupFutureUse
            case .setup:
                self = .setup
            }
        }

        /// Only payments are "Pay with Link". Collecting a payment method is like setting one up.
        init(_ buttonMode: LinkWalletButtonViewModel.Mode) {
            switch buttonMode {
            case .payment:
                self = .payment
            case .setup, .paymentMethod:
                self = .setup
            }
        }
    }

    private let apiClient: STPAPIClient
    let mode: Mode
    private let elementsSession: STPElementsSession
    private let intent: Intent
    private let paymentElementConfiguration: PaymentElementConfiguration
    private let initialLinkBrand: LinkBrand
    private let appearance: LinkAppearance?
    private let configuration: LinkConfiguration?
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private let requestSurface: LinkRequestSurface
    let nativeSheetPresentation: SheetImplementationResolver

    private lazy var linkAccountService: LinkAccountServiceProtocol = {
        LinkAccountService(apiClient: apiClient, elementsSession: elementsSession, analyticsHelper: analyticsHelper.linkAnalytics)
    }()

    var selectedPaymentDetails: ConsumerPaymentDetails? {
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

    /// Confirms intents outside of the Link sheet, e.g. with a payment method the customer selected in Link.
    private lazy var paymentHandler = STPPaymentHandler(apiClient: apiClient)

    /// The customer's email address and phone number, set through `LinkWalletButtonViewModel`. A Link wallet button looks
    /// up the email's Link account to display its details, and prefills both in Link.
    @Published var email: String?
    @Published var phoneNumber: String?

    /// Details on the current Link account.
    @Published @_spi(InternalOnlyAPI) public private(set) var linkAccount: PaymentSheetLinkAccount?

    /// A preview of the currently selected Link payment method.
    @Published @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public private(set) var paymentMethodPreview: PaymentMethodPreview?

    /// Forces the Link brand of `LinkController`s created afterwards, for testing. In production, the brand is chosen by Stripe.
    @_spi(InternalOnlyAPI) public static var forcedLinkBrandForTesting: LinkBrand?

    var resolvedLinkBrand: LinkBrand {
        paymentElementConfiguration.link.brand
            ?? linkAccount?.linkBrand
            ?? LinkAccountContext.shared.account?.linkBrand
            ?? initialLinkBrand
    }

    @_spi(InternalOnlyAPI) public var elementsSessionID: String {
        elementsSession.sessionID
    }

    /// The merchant's intent configuration, which Link confirms in `present`.
    /// `nil` if the controller was created without one, and only collects payment methods.
    let intentConfiguration: PaymentSheet.IntentConfiguration?

    /// Whether `present` uses native Link. If `false`, it uses the Link web popup instead.
    let usesNativeLink: Bool

    /// How `present` completes, when the controller backs a `LinkWalletButtonViewModel`. With `.payment` or `.setup`, Link
    /// loads the intent from its `clientSecretProvider` when presented, and confirms it.
    let buttonMode: LinkWalletButtonViewModel.Mode?

    /// Completion handler for full consent screen
    private var fullConsentCompletion: ((Result<AuthorizationResult, Error>) -> Void)?

    init(
        apiClient: STPAPIClient = .shared,
        mode: Mode,
        elementsSession: STPElementsSession,
        intent: Intent,
        intentConfiguration: PaymentSheet.IntentConfiguration? = nil,
        buttonMode: LinkWalletButtonViewModel.Mode? = nil,
        usesNativeLink: Bool = true,
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
        self.intentConfiguration = intentConfiguration
        self.buttonMode = buttonMode
        self.usesNativeLink = usesNativeLink
        self.paymentElementConfiguration = paymentElementConfiguration
        self.initialLinkBrand = linkBrand
        self.appearance = appearance
        self.configuration = configuration
        self.analyticsHelper = analyticsHelper
        self.requestSurface = requestSurface
        self.nativeSheetPresentation = SheetImplementationResolver(elementsSession: elementsSession)

        LinkAccountContext.shared.addObserver(self, selector: #selector(onLinkAccountChange))
    }

    deinit {
        // Just to make sure no observers stay around
        LinkAccountContext.shared.removeObserver(self)
    }

    @_spi(InternalOnlyAPI) public static var linkIcon: UIImage = Image.link_icon.makeImage()

    /// Formats card details using the same localized funding description and masking as a selected Link card.
    /// - Parameters:
    ///   - brand: The card brand.
    ///   - funding: The card funding value returned by the PaymentMethod API, such as `credit` or `debit`.
    ///   - last4: The last four digits of the card.
    @_spi(InternalOnlyAPI) public nonisolated static func formattedCardDetails(brand: STPCardBrand, funding: String?, last4: String) -> String {
        let linkFunding = ConsumerPaymentDetails.Details.Card.Funding(rawValue: funding?.uppercased() ?? "") ?? .unparsable
        return ConsumerPaymentDetails.Details.Card.formattedString(brand: brand, funding: linkFunding, last4: last4)
    }

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
        case .generic:
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
            paymentMethodPreview = webPaymentMethodPreview()
            return
        }

        let type: PaymentMethodPreview.PaymentMethodType = switch selectedPaymentDetails.details {
        case .card, .generic:
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

    private func webPaymentMethodPreview() -> PaymentMethodPreview? {
        Self.webPaymentMethodPreview(
            for: internalPaymentOption,
            linkBrand: resolvedLinkBrand,
            reduceLinkBranding: appearance?.reduceLinkBranding ?? false
        )
    }

    /// The payment method returned by the Link web popup, which has no Link payment details.
    var selectedWebPaymentMethod: STPPaymentMethod? {
        guard case .link(.withPaymentMethod(_, let paymentMethod)) = internalPaymentOption else {
            return nil
        }
        return paymentMethod
    }

    /// The preview of a card or bank account payment method returned by the Link web popup, which has no Link payment
    /// details. Formatted like the preview of the equivalent Link payment details.
    static func webPaymentMethodPreview(
        for paymentOption: PaymentOption?,
        linkBrand: LinkBrand,
        reduceLinkBranding: Bool
    ) -> PaymentMethodPreview? {
        guard case .link(.withPaymentMethod(_, let paymentMethod)) = paymentOption else {
            return nil
        }
        if paymentMethod.isLinkCardBrandToken {
            // The token doesn't describe the payment method it stands in for, so only show Link
            return .init(paymentMethodType: .card, icon: linkIcon, label: linkBrand.displayName, sublabel: nil)
        }
        if let card = paymentMethod.card {
            return .init(
                paymentMethodType: .card,
                icon: reduceLinkBranding ? STPImageLibrary.cardBrandImage(for: card.brand) : linkIcon,
                label: linkBrand.displayName,
                sublabel: formattedCardDetails(brand: card.brand, funding: card.funding, last4: card.last4 ?? "")
            )
        }
        if let bankAccount = paymentMethod.usBankAccount {
            let bankIconCode = PaymentSheetImageLibrary.bankIconCode(for: bankAccount.bankName)
            return .init(
                paymentMethodType: .bankAccount,
                icon: reduceLinkBranding ? PaymentSheetImageLibrary.bankIcon(for: bankIconCode, iconStyle: .filled) : linkIcon,
                label: linkBrand.displayName,
                sublabel: "\(bankAccount.bankName) •••• \(bankAccount.last4)"
            )
        }
        return nil
    }

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this controller. Defaults to `.shared`.
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Parameter appearance: Link UI-specific appearance overrides. If not specified, `PaymentSheet.Appearance` defaults are used.
    /// - Parameter linkConfiguration: Configuration for Link behavior and content. If not specified, default behavior is used.
    /// - Parameter requestSurface: The request surface to use for API calls. Defaults to `ios_payment_element`.
    /// - Parameter completion: A closure that is called with the result of the creation. It returns a `LinkController` if successful, or an error if the creation failed.
    @_spi(InternalOnlyAPI) public static func create(
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
                paymentElementConfiguration.returnURL = configuration?.returnURL
                paymentElementConfiguration.link.brand = Self.forcedLinkBrandForTesting

                let analyticsHelper = PaymentSheetAnalyticsHelper(
                    integrationShape: .linkController,
                    configuration: paymentElementConfiguration
                )

                let loadResult = try await Self.loadElementsSession(
                    intentConfiguration: Self.collectionOnlyIntentConfiguration(linkConfiguration: configuration),
                    paymentElementConfiguration: paymentElementConfiguration,
                    analyticsHelper: analyticsHelper
                )

                if let error = nativeLinkUnavailableError(
                    elementsSession: loadResult.elementsSession,
                    configuration: paymentElementConfiguration
                ) {
                    completion(.failure(error))
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
    /// - Parameter intentConfiguration: Describes the PaymentIntent or SetupIntent to confirm. If provided, `present` completes
    ///   the payment or setup inside Link (e.g. with a "Pay $10.99" button): when the customer confirms, Link creates a payment
    ///   method and calls your `confirmHandler` (or `confirmationTokenConfirmHandler`). Create (and optionally confirm) the
    ///   intent on your server with the same values, and return its client secret. Link then confirms it, handling any next
    ///   actions such as 3D Secure, and `present` returns `.confirmed(paymentMethod)`.
    ///   If `nil`, `present` returns `.completed(paymentMethod)` with the customer's selected payment method, and you
    ///   complete the payment or setup.
    /// - Parameter appearance: Link UI appearance overrides.
    /// - Parameter configuration: Configuration for Link behaviour.
    /// - Parameter completion: Called with the ready `LinkController` or an error. Fails with `IntegrationError.linkUnavailable`
    ///   if Link isn't enabled, or `IntegrationError.configurationRequiresNativeLink` if native Link isn't available on the device
    ///   and the Link web popup can't satisfy `configuration`.
    @_spi(LinkControllerPreview) public static func create(
        apiClient: STPAPIClient = .shared,
        intentConfiguration: PaymentSheet.IntentConfiguration? = nil,
        appearance: LinkAppearance? = nil,
        configuration: LinkConfiguration? = nil,
        completion: @escaping (Result<LinkController, Error>) -> Void
    ) {
        create(
            apiClient: apiClient,
            intentConfiguration: intentConfiguration,
            buttonMode: nil,
            appearance: appearance,
            configuration: configuration,
            completion: completion
        )
    }

    /// Creates a `LinkController` for a `LinkWalletButtonViewModel`. With a `.payment` or `.setup` `buttonMode`, the session
    /// loaded here only collects payment methods. It's used before the customer taps the button, e.g. to look them up, and
    /// `present` loads the intent from the mode's `clientSecretProvider`.
    static func create(
        apiClient: STPAPIClient,
        intentConfiguration: PaymentSheet.IntentConfiguration?,
        buttonMode: LinkWalletButtonViewModel.Mode?,
        appearance: LinkAppearance?,
        configuration: LinkConfiguration?,
        completion: @escaping (Result<LinkController, Error>) -> Void
    ) {
        Task {
            do {
                let loadedIntentConfiguration = Self.makeIntentConfiguration(
                    intentConfiguration,
                    linkConfiguration: configuration
                )
                var paymentElementConfiguration = PaymentSheet.Configuration()
                paymentElementConfiguration.apiClient = apiClient
                if let appearance = appearance {
                    paymentElementConfiguration.style = appearance.style
                }
                if let merchantDisplayName = configuration?.merchantDisplayName {
                    paymentElementConfiguration.merchantDisplayName = merchantDisplayName
                }
                paymentElementConfiguration.returnURL = configuration?.returnURL
                paymentElementConfiguration.link.brand = Self.forcedLinkBrandForTesting

                let analyticsHelper = PaymentSheetAnalyticsHelper(
                    integrationShape: .linkController,
                    configuration: paymentElementConfiguration
                )

                let loadResult = try await Self.loadElementsSession(
                    intentConfiguration: loadedIntentConfiguration,
                    paymentElementConfiguration: paymentElementConfiguration,
                    analyticsHelper: analyticsHelper
                )

                if let error = linkUnavailableError(
                    elementsSession: loadResult.elementsSession,
                    configuration: paymentElementConfiguration,
                    linkConfiguration: configuration
                ) {
                    completion(.failure(error))
                    return
                }

                let controller = LinkController(
                    apiClient: apiClient,
                    mode: buttonMode.map(Mode.init) ?? Mode(loadedIntentConfiguration.mode),
                    elementsSession: loadResult.elementsSession,
                    intent: loadResult.intent,
                    intentConfiguration: intentConfiguration == nil ? nil : loadedIntentConfiguration,
                    buttonMode: buttonMode,
                    usesNativeLink: deviceCanUseNativeLink(
                        elementsSession: loadResult.elementsSession,
                        configuration: paymentElementConfiguration
                    ),
                    paymentElementConfiguration: paymentElementConfiguration,
                    linkBrand: paymentElementConfiguration.resolvedLinkBrand(
                        elementsSession: loadResult.elementsSession,
                        linkAccount: LinkAccountContext.shared.account
                    ),
                    appearance: appearance,
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    requestSurface: .standaloneLink
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
    @_spi(InternalOnlyAPI) public func lookupConsumer(with email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
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
    @_spi(InternalOnlyAPI) public func lookupLinkAuthToken(
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
    @_spi(InternalOnlyAPI) public func registerLinkUser(
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
            analyticsHelper: analyticsHelper.linkAnalytics,
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
    @_spi(InternalOnlyAPI) public func presentForVerification(
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
            appearance: appearance,
            analyticsHelper: analyticsHelper.linkAnalytics
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
    @_spi(InternalOnlyAPI) public func collectPaymentMethod(
        from presentingViewController: UIViewController,
        with email: String?,
        supportedPaymentMethodTypes: [LinkPaymentMethodType]? = nil,
        collectName: Bool = false,
        completion: @escaping (_ didSelectPaymentMethod: Bool) -> Void
    ) {
        var paymentElementConfiguration = self.paymentElementConfiguration
        paymentElementConfiguration.defaultBillingDetails.email = email

        if let billingConfig = configuration?.billingDetailsCollectionConfiguration {
            paymentElementConfiguration.billingDetailsCollectionConfiguration = billingConfig
        }
        if collectName {
            paymentElementConfiguration.billingDetailsCollectionConfiguration.name = .always
        }

        // TODO: We need a way to override Link's default primary button label, since we don't want to show "Pay $xx.xx" even for payment mode.
        print("Presenting Link wallet for \(mode)")

        presentingViewController.presentNativeLink(
            selectedPaymentDetailsID: selectedPaymentDetails?.stripeID,
            configuration: paymentElementConfiguration,
            nativeSheetPresentation: nativeSheetPresentation,
            intent: intent,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper,
            supportedPaymentMethodTypes: resolvedSupportedPaymentMethodTypes(
                override: supportedPaymentMethodTypes
            ),
            linkAppearance: appearance,
            linkConfiguration: configuration,
            canContinueWithoutLink: false
        ) { [weak self] confirmOption, shouldClearSelection, _ in
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

    /// Presents the full Link flow, handling lookup, authentication or signup, and wallet display in a single call.
    ///
    /// Under the hood, this method:
    /// 1. Looks up the consumer by email, unless an authenticated session for that email already exists.
    ///    If `email` is `nil`, skips the lookup, and the customer enters their email in Link.
    /// 2. Presents the Link sheet, routing to signup, OTP verification, or the wallet based on account state.
    ///    If `phoneNumber` is provided, it is prefilled in the signup form.
    /// 3. Completes based on how the `LinkController` was created:
    ///    - With an `IntentConfiguration`: the wallet's primary button completes the payment or setup (e.g. "Pay $10.99").
    ///      Link creates a payment method, calls your `confirmHandler`, and confirms the intent, handling authentication
    ///      such as 3D Secure in the sheet. The completion is called once the intent is confirmed.
    ///    - Without an `IntentConfiguration`: once the user selects a payment method, creates and returns an `STPPaymentMethod`.
    ///      Use it to confirm a SetupIntent with `confirmSetupIntent`, or to complete the payment or setup on your server.
    ///
    /// In both cases, `paymentMethodPreview` is updated to show the payment method the customer used, e.g. on a confirmation screen.
    ///
    /// If native Link isn't available on the device, Link opens in a secure web popup instead, with the same results.
    ///
    /// - Parameter email: The email address to look up and associate with the Link account. If `nil`, the customer enters it in Link.
    /// - Parameter phoneNumber: Optional phone number in E.164 format to prefill during signup.
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Parameter completion: A closure called with `.success(.confirmed(paymentMethod))` once Link confirms the intent
    ///   (with an `IntentConfiguration`), `.success(.completed(paymentMethod))` once the customer selects a payment method
    ///   (without one), `.success(.canceled)` if the user dismisses the flow, or `.failure(error)` on API, network, or
    ///   confirmation errors.
    @_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public func present(
        email: String?,
        phoneNumber: String? = nil,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        lookupConsumerIfNeeded(email: email) { [weak self] error in
            guard let self else { return }
            if let error {
                completion(.failure(error))
                return
            }
            let configuration = self.walletConfiguration(email: email, phoneNumber: phoneNumber)
            switch self.buttonMode {
            case .payment(let clientSecretProvider):
                self.presentForClientSecretConfirmation(clientSecretProvider: clientSecretProvider, isPayment: true, configuration: configuration, from: presentingViewController, completion: completion)
                return
            case .setup(let clientSecretProvider):
                self.presentForClientSecretConfirmation(clientSecretProvider: clientSecretProvider, isPayment: false, configuration: configuration, from: presentingViewController, completion: completion)
                return
            case .paymentMethod, nil:
                break
            }
            if let intentConfiguration = self.intentConfiguration {
                self.presentForConfirmation(
                    intent: self.intent,
                    elementsSession: self.elementsSession,
                    configuration: configuration,
                    from: presentingViewController,
                    makeConfirmHandler: {
                        self.makeConfirmHandler(configuration: configuration, intentConfiguration: intentConfiguration, onPaymentMethodCreated: $0)
                    },
                    completion: completion
                )
            } else if self.usesNativeLink {
                self.presentWalletForSelection(configuration: configuration, from: presentingViewController, completion: completion)
            } else {
                self.presentWebForSelection(configuration: configuration, from: presentingViewController, completion: completion)
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
    @_spi(InternalOnlyAPI) public func createPaymentMethod(
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
    @_spi(InternalOnlyAPI) public func authorize(
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
    @_spi(InternalOnlyAPI) public func updatePhoneNumber(
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
    @_spi(InternalOnlyAPI) public func presentKYCVerification(
        info: VerifyKYCInfo,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onConfirm: @escaping (() async throws -> Void)
    ) async throws -> VerifyKYCResult {
        let verifyKYCViewController = VerifyKYCViewController(
            info: info,
            appearance: appearance,
            nativeSheetPresentation: nativeSheetPresentation
        )
        // The coordinator is used again for dismissal, so this operation owns it while awaiting user input.
        let result: VerifyKYCResult = await withCheckedContinuation { continuation in
            verifyKYCViewController.onResult = { [weak verifyKYCViewController] result in
                verifyKYCViewController?.onResult = nil
                continuation.resume(returning: result)
            }
            viewController.presentAsSheet(verifyKYCViewController.sheetContainer)
        }

        var completionResult: Result<VerifyKYCResult, Swift.Error> = .success(result)
        if case .confirmed = result {
            do {
                // Complete any async operation from the caller before dismissing.
                try await onConfirm()
            } catch {
                completionResult = .failure(error)
            }
        }

        // We'll report the result back to the caller after dismissal of the sheet.
        await withCheckedContinuation { continuation in
            verifyKYCViewController.dismiss(animated: true) {
                continuation.resume(returning: ())
            }
        }
        return try completionResult.get()
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
    @_spi(InternalOnlyAPI) public func presentUserAttestation(
        html: String,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onConfirm: @escaping (() async throws -> Void)
    ) async throws -> UserAttestationResult {
        let result = try await presentHTMLConfirmation(
            heading: String.Localized.user_attestation,
            html: html,
            confirmationButtonTitle: String.Localized.accept,
            appearance: appearance,
            from: viewController,
            onConfirm: onConfirm
        )

        switch result {
        case .confirmed:
            return .confirmed
        case .canceled:
            return .canceled
        }
    }

    /// Presents terms and conditions to the user.
    ///
    /// This method presents a bottom sheet displaying the provided terms and conditions HTML for user review.
    /// The user can accept the terms and conditions or cancel.
    ///
    /// - Parameters:
    ///   - html: The terms and conditions HTML to display to the user.
    ///   - appearance: Appearance configuration for the terms and conditions UI.
    ///   - viewController: The view controller from which to present the terms and conditions.
    ///   - onAccept: An async closure called when the user accepts. This is called *before* dismissal, allowing the caller to complete any async operations before the sheet is dismissed.
    /// - Returns: A `PartnerTermsResult` indicating whether the user accepted or canceled.
    /// Throws any error thrown by the `onAccept` handler.
    @_spi(InternalOnlyAPI) public func presentTermsAndConditions(
        html: String,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onAccept: @escaping (() async throws -> Void)
    ) async throws -> PartnerTermsResult {
        let result = try await presentHTMLConfirmation(
            heading: String.Localized.terms_and_conditions,
            html: html,
            confirmationButtonTitle: String.Localized.accept,
            appearance: appearance,
            from: viewController,
            onConfirm: onAccept
        )

        switch result {
        case .confirmed:
            return .accepted
        case .canceled:
            return .canceled
        }
    }

    /// Presents terms of service to the user.
    ///
    /// This method presents a bottom sheet displaying the provided terms of service HTML for user review.
    /// The user can accept the terms of service or cancel.
    ///
    /// - Parameters:
    ///   - html: The terms of service HTML to display to the user.
    ///   - appearance: Appearance configuration for the terms of service UI.
    ///   - viewController: The view controller from which to present the terms of service.
    ///   - onAccept: An async closure called when the user accepts. This is called *before* dismissal, allowing the caller to complete any async operations before the sheet is dismissed.
    /// - Returns: A `PartnerTermsResult` indicating whether the user accepted or canceled.
    /// Throws any error thrown by the `onAccept` handler.
    @_spi(InternalOnlyAPI) public func presentTermsOfService(
        html: String,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onAccept: @escaping (() async throws -> Void)
    ) async throws -> PartnerTermsResult {
        let result = try await presentHTMLConfirmation(
            heading: String.Localized.terms_of_service,
            html: html,
            confirmationButtonTitle: String.Localized.accept,
            appearance: appearance,
            from: viewController,
            onConfirm: onAccept
        )

        switch result {
        case .confirmed:
            return .accepted
        case .canceled:
            return .canceled
        }
    }

    private func presentHTMLConfirmation(
        heading: String,
        html: String,
        confirmationButtonTitle: String,
        appearance: LinkAppearance,
        from viewController: UIViewController,
        onConfirm: @escaping (() async throws -> Void)
    ) async throws -> HTMLConfirmationResult {
        let confirmationViewController = HTMLConfirmationViewController(
            heading: heading,
            html: html,
            confirmationButtonTitle: confirmationButtonTitle,
            appearance: appearance,
            brand: resolvedLinkBrand,
            nativeSheetPresentation: nativeSheetPresentation
        )
        // The coordinator is used again for dismissal, so this operation owns it while awaiting user input.
        let result: HTMLConfirmationResult = await withCheckedContinuation { continuation in
            confirmationViewController.onResult = { [weak confirmationViewController] result in
                confirmationViewController?.onResult = nil
                continuation.resume(returning: result)
            }
            viewController.presentAsSheet(confirmationViewController.sheetContainer)
        }

        var completionResult: Result<HTMLConfirmationResult, Swift.Error> = .success(result)
        if case .confirmed = result {
            do {
                try await onConfirm()
            } catch {
                completionResult = .failure(error)
            }
        }

        // Dismiss before returning, even when confirmation fails.
        await withCheckedContinuation { continuation in
            confirmationViewController.dismiss(animated: true) {
                continuation.resume(returning: ())
            }
        }
        return try completionResult.get()
    }

    /// Logs out the current Link user, if any.
    @_spi(InternalOnlyAPI) public func logOut(completion: @escaping (Result<Void, Error>) -> Void) {
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

    /// Looks up the consumer by email, unless an authenticated session for that email already exists.
    /// Without an email, keeps the current Link session (if any), so the customer can sign in or continue in Link.
    private func lookupConsumerIfNeeded(email: String?, completion: @escaping (Error?) -> Void) {
        guard let email, !email.isEmpty else {
            completion(nil)
            return
        }
        // The Link web popup prefills the current Link account's email, or else `email`. So it only needs a lookup when
        // the current account is for a different email. Skipping it opens the popup sooner.
        let currentAccountEmail = LinkAccountContext.shared.account?.email
        if !usesNativeLink, currentAccountEmail == nil || currentAccountEmail?.lowercased() == email.lowercased() {
            completion(nil)
            return
        }
        let alreadyAuthenticated = linkAccount?.sessionState == .verified
            && linkAccount?.email.lowercased() == email.lowercased()
        guard !alreadyAuthenticated else {
            completion(nil)
            return
        }
        lookupConsumer(with: email) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success:
                completion(nil)
            }
        }
    }

    /// The configuration used to present the Link wallet for the given customer details.
    private func walletConfiguration(email: String?, phoneNumber: String?) -> PaymentElementConfiguration {
        var paymentElementConfiguration = self.paymentElementConfiguration
        paymentElementConfiguration.defaultBillingDetails.email = email
        if let phoneNumber {
            paymentElementConfiguration.defaultBillingDetails.phone = phoneNumber
        }
        if let billingConfig = configuration?.billingDetailsCollectionConfiguration {
            paymentElementConfiguration.billingDetailsCollectionConfiguration = billingConfig
        }
        return paymentElementConfiguration
    }

    /// Presents the Link wallet for the customer to select a payment method, then creates it.
    private func presentWalletForSelection(
        configuration: PaymentElementConfiguration,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        presentingViewController.presentNativeLink(
            selectedPaymentDetailsID: nil,
            configuration: configuration,
            nativeSheetPresentation: nativeSheetPresentation,
            intent: intent,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper,
            supportedPaymentMethodTypes: resolvedSupportedPaymentMethodTypes(override: nil),
            linkAppearance: appearance,
            linkConfiguration: self.configuration,
            canContinueWithoutLink: false
        ) { [weak self] confirmOption, _, error in
            guard let self else { return }
            if let error {
                completion(.failure(error))
                return
            }
            guard let confirmOption else {
                completion(.success(.canceled))
                return
            }
            if case .wallet = confirmOption {
                // Native Link handed off to the web flow, e.g. because attestation failed
                self.presentWebForSelection(configuration: configuration, from: presentingViewController, completion: completion)
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

    /// Presents the Link web popup for the customer to select a payment method, when native Link isn't available.
    private func presentWebForSelection(
        configuration: PaymentElementConfiguration,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        LinkWebPaymentMethodSelector().present(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            analyticsHelper: analyticsHelper,
            from: presentingViewController
        ) { [weak self] paymentOption in
            guard let self else { return }
            guard let paymentOption, case .link(.withPaymentMethod(_, let paymentMethod)) = paymentOption else {
                completion(.success(.canceled))
                return
            }
            self.internalPaymentOption = paymentOption
            self.lastCreatedPaymentMethod = paymentMethod
            completion(.success(.completed(paymentMethod)))
        }
    }

    /// The Link option the customer confirmed with inside Link, and the payment method created for it.
    private typealias Confirmation = (paymentOption: PaymentOption, paymentMethod: STPPaymentMethod)

    /// Presents Link, which confirms `intent` inside the sheet: native Link, or the Link web popup when native Link isn't
    /// available. `makeConfirmHandler` makes the handler that confirms the intent, given a closure to call with the
    /// payment method it confirms with.
    private func presentForConfirmation(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        from presentingViewController: UIViewController,
        makeConfirmHandler: (@escaping (Confirmation) -> Void) -> PayWithNativeLinkController.ConfirmHandler,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        var confirmation: Confirmation?
        let confirmHandler = makeConfirmHandler { confirmation = $0 }
        guard usesNativeLink else {
            let payWithLink = PayWithLinkController(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                nativeSheetPresentation: nativeSheetPresentation,
                analyticsHelper: analyticsHelper,
                confirmationChallenge: nil,
                confirmHandler: confirmHandler
            )
            payWithLink.present(from: presentingViewController) { [weak self] result, _ in
                self?.finishConfirmation(result: result, confirmation: confirmation, completion: completion)
            }
            return
        }
        let payWithNativeLink = PayWithNativeLinkController(
            mode: .full,
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            paymentHandler: STPPaymentHandler(apiClient: apiClient),
            nativeSheetPresentation: nativeSheetPresentation,
            analyticsHelper: analyticsHelper,
            supportedPaymentMethodTypes: resolvedSupportedPaymentMethodTypes(override: nil),
            linkAppearance: appearance,
            linkConfiguration: self.configuration,
            confirmHandler: confirmHandler
        )
        payWithNativeLink.presentAsSheet(
            from: presentingViewController,
            shouldOfferApplePay: false,
            hidingUnderlyingBottomSheet: false,
            shouldFinishOnClose: true,
            canContinueWithoutLink: false
        ) { [weak self] result, _, _ in
            self?.finishConfirmation(result: result, confirmation: confirmation, completion: completion)
        }
    }

    /// Gets a client secret from a Link wallet button's `clientSecretProvider` and loads its intent, then presents Link,
    /// which confirms the intent.
    private func presentForClientSecretConfirmation(
        clientSecretProvider: @escaping () async throws -> String,
        isPayment: Bool,
        configuration: PaymentElementConfiguration,
        from presentingViewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let loadResult: PaymentSheetLoader.LoadResult
            do {
                let clientSecret = try await clientSecretProvider()
                if let error = Self.intentMismatchError(clientSecret: clientSecret, isPayment: isPayment) {
                    throw error
                }
                // Loading also looks up a Link account for the configuration's email, and replaces the current one with
                // it, so keep the account that `present` looked up. Link opens for it, e.g. with its email prefilled.
                let linkAccount = LinkAccountContext.shared.account
                defer { LinkAccountContext.shared.account = linkAccount }
                loadResult = try await Self.loadElementsSession(
                    mode: isPayment ? .paymentIntentClientSecret(clientSecret) : .setupIntentClientSecret(clientSecret),
                    paymentElementConfiguration: self.paymentElementConfiguration,
                    analyticsHelper: self.analyticsHelper
                )
                // The intent's payment method types or account can make Link unavailable
                if let error = Self.linkUnavailableError(
                    elementsSession: loadResult.elementsSession,
                    configuration: self.paymentElementConfiguration,
                    linkConfiguration: self.configuration
                ) {
                    throw error
                }
            } catch {
                completion(.failure(error))
                return
            }
            self.presentForConfirmation(
                intent: loadResult.intent,
                elementsSession: loadResult.elementsSession,
                configuration: configuration,
                from: presentingViewController,
                makeConfirmHandler: { self.makeClientSecretConfirmHandler(onPaymentMethodCreated: $0) },
                completion: completion
            )
        }
    }

    /// The error if `clientSecret` is for the other kind of intent than the Link wallet button's mode. Malformed client
    /// secrets aren't caught here, and fail when the intent is loaded.
    static func intentMismatchError(clientSecret: String, isPayment: Bool) -> IntegrationError? {
        let isPaymentIntent = STPPaymentIntentConfirmParams.isClientSecretValid(clientSecret)
        let isSetupIntent = STPSetupIntentConfirmParams.isClientSecretValid(clientSecret)
        if isPayment ? isSetupIntent : isPaymentIntent {
            return .intentMismatch
        }
        return nil
    }

    /// A Link confirm handler for an intent loaded from a client secret: creates the payment method for the Link option
    /// the customer confirmed with, then confirms the intent with it.
    private func makeClientSecretConfirmHandler(
        onPaymentMethodCreated: @escaping (Confirmation) -> Void
    ) -> PayWithNativeLinkController.ConfirmHandler {
        return { [weak self] authenticationContext, intent, elementsSession, paymentOption, completion in
            guard let self else { return }
            Task { @MainActor in
                let clientSecret: String
                let isPayment: Bool
                switch intent {
                case .paymentIntent(let paymentIntent):
                    clientSecret = paymentIntent.clientSecret
                    isPayment = true
                case .setupIntent(let setupIntent):
                    clientSecret = setupIntent.clientSecret
                    isPayment = false
                case .deferredIntent, .checkout:
                    stpAssertionFailure("Unexpected intent when confirming a client secret with Link: \(intent)")
                    completion(.failed(error: PaymentSheetError.unknown(debugDescription: "Unexpected intent when confirming with Link.")), nil)
                    return
                }
                do {
                    let paymentMethod = try await self.createPaymentMethodForConfirmation(
                        with: paymentOption,
                        intent: intent,
                        elementsSession: elementsSession,
                        intentConfiguration: nil
                    )
                    onPaymentMethodCreated((paymentOption, paymentMethod))
                    let result = await self.confirmIntent(
                        clientSecret: clientSecret,
                        isPayment: isPayment,
                        paymentMethod: paymentMethod,
                        authenticationContext: authenticationContext
                    )
                    switch result {
                    case .success(.canceled):
                        completion(.canceled, nil)
                    case .success:
                        completion(.completed, nil)
                    case .failure(let error):
                        completion(.failed(error: error), nil)
                    }
                } catch {
                    completion(.failed(error: error), nil)
                }
            }
        }
    }

    /// Confirms a PaymentIntent or SetupIntent with a payment method created from Link, on the client, handling next
    /// actions such as 3D Secure. Like PaymentSheet's Link confirmation, sends mandate data inferred from the client: Link
    /// payment methods need it when they're saved for future use.
    private func confirmIntent(
        clientSecret: String,
        isPayment: Bool,
        paymentMethod: STPPaymentMethod,
        authenticationContext: STPAuthenticationContext
    ) async -> Result<PaymentMethodResult, Error> {
        func result(
            status: STPPaymentHandlerActionStatus,
            confirmedPaymentMethod: STPPaymentMethod?,
            error: Error?
        ) -> Result<PaymentMethodResult, Error> {
            switch status {
            case .succeeded:
                return .success(.confirmed(confirmedPaymentMethod ?? paymentMethod))
            case .canceled:
                return .success(.canceled)
            case .failed:
                return .failure(error ?? PaymentSheetError.unknown(debugDescription: "Confirmation failed without an error."))
            @unknown default:
                return .failure(PaymentSheetError.unknown(debugDescription: "Unexpected STPPaymentHandlerActionStatus."))
            }
        }

        return await withCheckedContinuation { continuation in
            if isPayment {
                let params = STPPaymentIntentConfirmParams(clientSecret: clientSecret)
                params.paymentMethodId = paymentMethod.stripeId
                params.returnURL = paymentElementConfiguration.returnURL
                params.mandateData = .makeWithInferredValues()
                paymentHandler.confirmPaymentIntent(params: params, authenticationContext: authenticationContext) { status, _, error in
                    continuation.resume(returning: result(status: status, confirmedPaymentMethod: nil, error: error))
                }
            } else {
                let params = STPSetupIntentConfirmParams(clientSecret: clientSecret)
                params.paymentMethodID = paymentMethod.stripeId
                params.returnURL = paymentElementConfiguration.returnURL
                params.mandateData = .makeWithInferredValues()
                paymentHandler.confirmSetupIntent(params: params, authenticationContext: authenticationContext) { status, setupIntent, error in
                    continuation.resume(returning: result(status: status, confirmedPaymentMethod: setupIntent?.paymentMethod, error: error))
                }
            }
        }
    }

    /// A Link confirm handler that creates the payment method for the Link option the customer confirmed with, then
    /// confirms the merchant's intent with it. Creating the payment method here, rather than letting PaymentSheet create it
    /// during confirmation, means there's always one to return, including when confirming with a confirmation token.
    private func makeConfirmHandler(
        configuration: PaymentElementConfiguration,
        intentConfiguration: PaymentSheet.IntentConfiguration,
        onPaymentMethodCreated: @escaping (Confirmation) -> Void
    ) -> PayWithNativeLinkController.ConfirmHandler {
        return { [weak self] authenticationContext, intent, elementsSession, paymentOption, completion in
            guard let self else { return }
            Task { @MainActor in
                do {
                    let paymentMethod = try await self.createPaymentMethodForConfirmation(
                        with: paymentOption,
                        intent: intent,
                        elementsSession: elementsSession,
                        intentConfiguration: intentConfiguration
                    )
                    onPaymentMethodCreated((paymentOption, paymentMethod))
                    // Confirmation only logs the consumer out for merchants without attestation, which only use the web
                    // flow and have no native Link session to keep.
                    let (result, deferredIntentConfirmationType) = await PaymentSheet.routeDeferredIntentConfirmation(
                        confirmType: .saved(paymentMethod, paymentOptions: nil, clientAttributionMetadata: nil, radarOptions: nil),
                        configuration: configuration,
                        intentConfig: intentConfiguration,
                        authenticationContext: authenticationContext,
                        paymentHandler: STPPaymentHandler(apiClient: self.apiClient),
                        isFlowController: false,
                        elementsSession: elementsSession,
                        isFromLink: true
                    )
                    completion(result, deferredIntentConfirmationType)
                } catch {
                    completion(.failed(error: error), nil)
                }
            }
        }
    }

    /// The payment method for the Link option the customer confirmed with: the one returned by the Link web popup, or one
    /// created from their Link payment details the same way PaymentSheet does when confirming with Link.
    private func createPaymentMethodForConfirmation(
        with paymentOption: PaymentOption,
        intent: Intent,
        elementsSession: STPElementsSession,
        intentConfiguration: PaymentSheet.IntentConfiguration?
    ) async throws -> STPPaymentMethod {
        guard case .link(let confirmOption) = paymentOption else {
            stpAssertionFailure("Unexpected payment option when confirming with Link: \(paymentOption)")
            throw PaymentSheetError.unknown(debugDescription: "Unexpected payment option when confirming with Link.")
        }
        switch confirmOption {
        case .withPaymentMethod(_, let paymentMethod):
            return paymentMethod
        case .withPaymentDetails(_, let linkAccount, let paymentDetails, let confirmationExtras, _):
            let allowRedisplay = paymentDetails.computeAllowRedisplay(
                elementsSession: elementsSession,
                isSettingUp: { paymentMethodType in
                    intent.isSetupFutureUsageSet(for: paymentMethodType) || elementsSession.forceSaveFutureUseBehaviorAndNewMandateText
                }
            )
            let billingPhoneNumber = confirmationExtras?.billingPhoneNumber
            if elementsSession.linkPassthroughModeEnabled {
                return try await withCheckedThrowingContinuation { continuation in
                    linkAccount.sharePaymentDetails(
                        id: paymentDetails.stripeID,
                        cvc: paymentDetails.cvc,
                        allowRedisplay: allowRedisplay,
                        expectedPaymentMethodType: paymentDetails.expectedPaymentMethodTypeForPassthroughMode(elementsSession),
                        billingPhoneNumber: billingPhoneNumber,
                        clientAttributionMetadata: nil
                    ) { result in
                        continuation.resume(with: result.map(\.paymentMethod))
                    }
                }
            }
            guard let paymentMethodParams = linkAccount.makePaymentMethodParams(
                from: paymentDetails,
                cvc: paymentDetails.cvc,
                billingPhoneNumber: billingPhoneNumber,
                allowRedisplay: allowRedisplay
            ) else {
                throw PaymentSheetError.payingWithoutValidLinkSession
            }
            return try await apiClient.createPaymentMethod(
                with: paymentMethodParams,
                additionalPaymentUserAgentValues: intentConfiguration.map { PaymentSheet.makeDeferredPaymentUserAgentValue(intentConfiguration: $0) } ?? []
            )
        case .wallet, .signUp:
            stpAssertionFailure("Unexpected Link confirm option when confirming inside Link: \(confirmOption)")
            throw PaymentSheetError.unknown(debugDescription: "Unexpected Link confirm option when confirming inside Link.")
        }
    }

    /// Maps the result of confirming inside Link to `present`'s result. On success, applies the Link option the customer
    /// confirmed with, so that `paymentMethodPreview` shows the payment method that was used.
    private func finishConfirmation(
        result: PaymentSheetResult,
        confirmation: Confirmation?,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        switch result {
        case .completed:
            guard let confirmation else {
                stpAssertionFailure("Link completed without creating a payment method.")
                completion(.failure(PaymentSheetError.unknown(debugDescription: "Link completed without a payment method.")))
                return
            }
            internalPaymentOption = confirmation.paymentOption
            completion(.success(.confirmed(confirmation.paymentMethod)))
        case .canceled:
            completion(.success(.canceled))
        case .failed(let error):
            completion(.failure(error))
        }
    }

    private func confirmSetupIntentInternal(
        clientSecret: String,
        paymentMethod: STPPaymentMethod,
        from viewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        Task { @MainActor in
            let result = await confirmIntent(
                clientSecret: clientSecret,
                isPayment: false,
                paymentMethod: paymentMethod,
                authenticationContext: ViewControllerAuthenticationContext(viewController: viewController)
            )
            // `confirmSetupIntent` has always returned `.completed` on success
            if case .success(.confirmed(let confirmedPaymentMethod)) = result {
                completion(.success(.completed(confirmedPaymentMethod)))
            } else {
                completion(result)
            }
        }
    }

    /// Confirms a PaymentIntent or SetupIntent with the payment method from the most recent `present`, for a
    /// `LinkWalletButtonViewModel` that collects a payment method. Returns `.confirmed(paymentMethod)` on success.
    func confirmIntent(
        clientSecret: String,
        isPayment: Bool,
        from viewController: UIViewController,
        completion: @escaping (Result<PaymentMethodResult, Error>) -> Void
    ) {
        guard let paymentMethod = lastCreatedPaymentMethod else {
            completion(.failure(IntegrationError.noPaymentMethodSelected))
            return
        }
        if let error = Self.intentMismatchError(clientSecret: clientSecret, isPayment: isPayment) {
            completion(.failure(error))
            return
        }
        Task { @MainActor in
            completion(await confirmIntent(
                clientSecret: clientSecret,
                isPayment: isPayment,
                paymentMethod: paymentMethod,
                authenticationContext: ViewControllerAuthenticationContext(viewController: viewController)
            ))
        }
    }

    private func updateLinkAccount(with consumerSession: ConsumerSession) {
        guard let linkAccount else {
            return
        }

        let updatedAccount = PaymentSheetLinkAccount(
            email: linkAccount.email,
            session: consumerSession,
            publishableKey: linkAccount.publishableKey,
            displayablePaymentDetails: linkAccount.displayablePaymentDetails,
            apiClient: linkAccount.apiClient,
            useMobileEndpoints: linkAccount.useMobileEndpoints,
            canSyncAttestationState: linkAccount.canSyncAttestationState,
            supportedVerificationTypes: linkAccount.supportedVerificationTypes,
            requestSurface: linkAccount.requestSurface,
            createdFromAuthIntentID: linkAccount.createdFromAuthIntentID
        )
        updatedAccount.authLookupSettings = linkAccount.authLookupSettings
        updatedAccount.authLookupEmail = linkAccount.authLookupEmail
        updatedAccount.authCountryCode = linkAccount.authCountryCode
        updatedAccount.authSessionLookup = linkAccount.authSessionLookup
        updatedAccount.visitedFallbackURLs = linkAccount.visitedFallbackURLs
        self.linkAccount = updatedAccount
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
            consentViewModel: consentViewModel,
            analyticsHelper: analyticsHelper.linkAnalytics
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

    /// The intent configuration used when the controller only collects payment methods:
    /// no real intent, PM creation and confirmation handled externally.
    static func collectionOnlyIntentConfiguration(linkConfiguration: LinkConfiguration?) -> PaymentSheet.IntentConfiguration {
        var intentConfiguration = PaymentSheet.IntentConfiguration(
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
        intentConfiguration.financialConnectionsPermissions = linkConfiguration?.financialConnectionsPermissions
        return intentConfiguration
    }

    /// The intent configuration to load the elements session with, and to confirm with in `present`.
    /// Without a merchant `intentConfiguration`, the controller only collects payment methods.
    static func makeIntentConfiguration(
        _ intentConfiguration: PaymentSheet.IntentConfiguration?,
        linkConfiguration: LinkConfiguration?
    ) -> PaymentSheet.IntentConfiguration {
        guard var intentConfiguration else {
            return collectionOnlyIntentConfiguration(linkConfiguration: linkConfiguration)
        }

        if let paymentMethodTypes = linkConfiguration?.paymentMethodTypes {
            assert(
                intentConfiguration.paymentMethodTypes == nil || intentConfiguration.paymentMethodTypes == paymentMethodTypes,
                "LinkConfiguration.paymentMethodTypes and IntentConfiguration.paymentMethodTypes are both set. The IntentConfiguration's value is used."
            )
            intentConfiguration.paymentMethodTypes = intentConfiguration.paymentMethodTypes ?? paymentMethodTypes
        }
        if let financialConnectionsPermissions = linkConfiguration?.financialConnectionsPermissions {
            intentConfiguration.financialConnectionsPermissions = financialConnectionsPermissions
        }

        return intentConfiguration
    }

    private static func loadElementsSession(
        intentConfiguration: PaymentSheet.IntentConfiguration,
        paymentElementConfiguration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) async throws -> PaymentSheetLoader.LoadResult {
        try await loadElementsSession(
            mode: .deferredIntent(intentConfiguration),
            paymentElementConfiguration: paymentElementConfiguration,
            analyticsHelper: analyticsHelper
        )
    }

    private static func loadElementsSession(
        mode: PaymentSheet.InitializationMode,
        paymentElementConfiguration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) async throws -> PaymentSheetLoader.LoadResult {
        let (result, _) = try await PaymentSheetLoader.load(
            mode: mode,
            configuration: paymentElementConfiguration,
            analyticsHelper: analyticsHelper,
            // TODO: Add a non-logging integration shape or something
            integrationShape: .paymentSheet
        )

        return result
    }

    /// Returns the error that prevents native Link from being used with the given session, if any.
    static func nativeLinkUnavailableError(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration
    ) -> IntegrationError? {
        // When Link is unavailable for the session (e.g. it's turned off in the merchant's payment method configuration),
        // the backend returns no funding sources and doesn't enable attestation either. Check this first so that we don't
        // misreport it as an attestation issue.
        guard let linkFundingSources = elementsSession.linkFundingSources, !linkFundingSources.isEmpty else {
            return .linkUnavailable
        }
        guard deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) else {
            return .missingAppAttestation
        }
        return nil
    }

    /// Returns the error that prevents Link from being used with the given session, if any.
    /// Unlike `nativeLinkUnavailableError`, allows falling back to the Link web popup when native Link isn't available,
    /// as long as the web popup can satisfy the Link configuration.
    static func linkUnavailableError(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkConfiguration: LinkConfiguration?
    ) -> IntegrationError? {
        guard let linkFundingSources = elementsSession.linkFundingSources, !linkFundingSources.isEmpty else {
            return .linkUnavailable
        }
        guard !deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) else {
            return nil
        }
        return webLinkCanSatisfy(configuration: configuration, linkConfiguration: linkConfiguration)
            ? nil
            : .configurationRequiresNativeLink
    }

    /// Whether the Link web popup can satisfy the configuration. It can't collect billing details,
    /// or limit the payment method types the customer can choose from.
    static func webLinkCanSatisfy(configuration: PaymentElementConfiguration, linkConfiguration: LinkConfiguration?) -> Bool {
        var configuration = configuration
        if let billingDetailsCollectionConfiguration = linkConfiguration?.billingDetailsCollectionConfiguration {
            configuration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration
        }
        if configuration.requiresBillingDetailCollection() {
            return false
        }
        if let supportedPaymentMethodTypes = nonEmptySupportedPaymentMethodTypes(linkConfiguration?.supportedPaymentMethodTypes),
           Set(supportedPaymentMethodTypes) != Set(LinkPaymentMethodType.allCases) {
            return false
        }
        return true
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

        let bottomSheetViewController = PaymentSheetContainerFactory.make(
            contentViewController: fullConsentViewController,
            appearance: paymentElementConfiguration.appearance,
            usesNativeSheet: nativeSheetPresentation.usesNativeSheet,
            didCancelNative3DS2: {}
        )

        // Store completion handler for use in delegate method
        self.fullConsentCompletion = completion

        viewController.presentAsSheet(bottomSheetViewController)
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

@_spi(InternalOnlyAPI) public extension LinkController {

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
    /// - Parameter intentConfiguration: Describes the PaymentIntent or SetupIntent to confirm. If provided, `present` completes
    ///   the payment or setup inside Link (e.g. with a "Pay $10.99" button): when the customer confirms, Link creates a payment
    ///   method and calls your `confirmHandler` (or `confirmationTokenConfirmHandler`). Create (and optionally confirm) the
    ///   intent on your server with the same values, and return its client secret. Link then confirms it, handling any next
    ///   actions such as 3D Secure, and `present` returns `.confirmed(paymentMethod)`.
    ///   If `nil`, `present` returns `.completed(paymentMethod)` with the customer's selected payment method, and you
    ///   complete the payment or setup.
    /// - Parameter appearance: Link UI appearance overrides.
    /// - Parameter configuration: Configuration for Link behaviour.
    /// - Returns: A `LinkController` if successful, or throws an error if creation failed.
    static func create(
        apiClient: STPAPIClient = .shared,
        intentConfiguration: PaymentSheet.IntentConfiguration? = nil,
        appearance: LinkAppearance? = nil,
        configuration: LinkConfiguration? = nil
    ) async throws -> LinkController {
        return try await withCheckedThrowingContinuation { continuation in
            create(
                apiClient: apiClient,
                intentConfiguration: intentConfiguration,
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

@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public extension LinkController {

    /// Presents the full Link flow, handling lookup, authentication or signup, and wallet display in a single call.
    ///
    /// If the `LinkController` was created with an `IntentConfiguration`, the payment or setup is completed inside Link.
    /// Otherwise, the customer selects a payment method, and you complete the payment or setup.
    /// If native Link isn't available on the device, Link opens in a secure web popup instead.
    /// See `present(email:phoneNumber:from:completion:)` for details.
    ///
    /// - Parameter email: The email address to look up and associate with the Link account. If `nil`, the customer enters it in Link.
    /// - Parameter phoneNumber: Optional phone number in E.164 format to prefill during signup.
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Returns: `.confirmed(paymentMethod)` once Link confirms the intent (with an `IntentConfiguration`),
    ///   `.completed(paymentMethod)` once the customer selects a payment method (without one), or `.canceled` if the user
    ///   dismisses the flow.
    /// - Throws: An error if the lookup, payment method creation, or confirmation fails.
    func present(
        email: String?,
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

/// Presents the Link web popup for the customer to select a payment method, and reports the resulting Link option.
@MainActor
private final class LinkWebPaymentMethodSelector: PayWithLinkWebControllerDelegate {
    private var completion: ((PaymentOption?) -> Void)?
    private var selfRetainer: LinkWebPaymentMethodSelector?

    func present(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        from presentingViewController: UIViewController,
        completion: @escaping (PaymentOption?) -> Void
    ) {
        // Retained while presented, like `PayWithLinkController`
        selfRetainer = self
        self.completion = completion
        let payWithLinkWebController = PayWithLinkWebController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            linkAccount: LinkAccountContext.shared.account,
            checkoutAttribution: analyticsHelper.checkoutAttribution,
            analyticsHelper: analyticsHelper.linkAnalytics
        )
        payWithLinkWebController.payWithLinkDelegate = self
        payWithLinkWebController.present(over: presentingViewController)
    }

    func payWithLinkWebControllerDidComplete(
        _ payWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption
    ) {
        finish(with: paymentOption)
    }

    func payWithLinkWebControllerDidCancel() {
        finish(with: nil)
    }

    private func finish(with paymentOption: PaymentOption?) {
        completion?(paymentOption)
        completion = nil
        selfRetainer = nil
    }
}
