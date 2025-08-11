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
@_spi(STP) import StripeUICore

/// A controller that presents a Link sheet to collect a customer's payment method.
@MainActor @_spi(STP) public class LinkController: ObservableObject {

    /// Represents the payment method currently selected by the user.
    @_spi(STP) public struct PaymentMethodPreview {

        /// The Link icon to render in your screen.
        @_spi(STP) public let icon: UIImage

        /// The Link label to render in your screen.
        @_spi(STP) public let label: String

        /// Details about the selected Link payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
        @_spi(STP) public let sublabel: String?
    }

    @frozen @_spi(STP) public enum VerificationResult {
        /// Verification was completed successfully.
        case completed
        /// Verification was canceled by the user.
        case canceled
    }

    /// Errors specific incorrect integrations with LinkController
    @_spi(STP) public enum IntegrationError: Error {
        case noPaymentMethodSelected
        case noActiveLinkConsumer
        case missingAppAttestation
    }

    @_spi(STP) public enum Mode {
        case payment
        case paymentAndSetupFutureUse
        case setup
    }

    private let apiClient: STPAPIClient
    private let mode: Mode
    private let elementsSession: STPElementsSession
    private let intent: Intent
    private let configuration: PaymentElementConfiguration
    private let appearance: LinkAppearance?
    private let analyticsHelper: PaymentSheetAnalyticsHelper

    private lazy var linkAccountService: LinkAccountServiceProtocol = {
        LinkAccountService(elementsSession: elementsSession)
    }()

    private var selectedPaymentDetails: ConsumerPaymentDetails? {
        guard case .link(let confirmOption) = internalPaymentOption else {
            return nil
        }
        guard case .withPaymentDetails(_, let paymentDetails, _, _) = confirmOption else {
            return nil
        }
        return paymentDetails
    }

    private var internalPaymentOption: PaymentOption? {
        didSet {
            guard let selectedPaymentDetails else {
                paymentMethodPreview = nil
                return
            }
            paymentMethodPreview = .init(
                icon: Self.linkIcon,
                label: STPPaymentMethodType.link.displayName,
                sublabel: selectedPaymentDetails.linkPaymentDetailsFormattedString
            )
        }
    }

    /// Details on the current Link account.
    @Published @_spi(STP) public private(set) var linkAccount: PaymentSheetLinkAccount?

    /// A preview of the currently selected Link payment method.
    @Published @_spi(STP) public private(set) var paymentMethodPreview: PaymentMethodPreview?

    /// The merchant logo URL from the elements session, if available.
    @_spi(STP) public var merchantLogoUrl: URL? {
        elementsSession.merchantLogoUrl
    }

    private init(
        apiClient: STPAPIClient = .shared,
        mode: Mode,
        elementsSession: STPElementsSession,
        intent: Intent,
        configuration: PaymentElementConfiguration,
        appearance: LinkAppearance?,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.apiClient = apiClient
        self.mode = mode
        self.elementsSession = elementsSession
        self.intent = intent
        self.configuration = configuration
        self.appearance = appearance
        self.analyticsHelper = analyticsHelper

        LinkAccountContext.shared.addObserver(self, selector: #selector(onLinkAccountChange))
    }

    deinit {
        // Just to make sure no observers stay around
        LinkAccountContext.shared.removeObserver(self)
    }

    @_spi(STP) public static var linkIcon: UIImage = Image.link_icon.makeImage()

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this controller. Defaults to `.shared`.
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Parameter appearance: Link UI-specific appearance overrides. If not specified, `PaymentSheet.Appearance` defaults are used.
    /// - Parameter completion: A closure that is called with the result of the creation. It returns a `LinkController` if successful, or an error if the creation failed.
    @_spi(STP) public static func create(
        apiClient: STPAPIClient = .shared,
        mode: LinkController.Mode,
        appearance: LinkAppearance? = nil,
        completion: @escaping (Result<LinkController, Error>) -> Void
    ) {
        Task {
            do {
                var configuration = PaymentSheet.Configuration()
                if let appearance = appearance {
                    configuration.style = appearance.style
                }

                let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: configuration)

                let loadResult = try await Self.loadElementsSession(
                    configuration: configuration,
                    analyticsHelper: analyticsHelper
                )

                guard deviceCanUseNativeLink(elementsSession: loadResult.elementsSession, configuration: configuration) else {
                    completion(.failure(IntegrationError.missingAppAttestation))
                    return
                }

                let controller = LinkController(
                    apiClient: apiClient,
                    mode: mode,
                    elementsSession: loadResult.elementsSession,
                    intent: loadResult.intent,
                    configuration: configuration,
                    appearance: appearance,
                    analyticsHelper: analyticsHelper
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
            linkAccountService: linkAccountService
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
        guard let linkAccount, linkAccount.sessionState == .requiresVerification else {
            let error = IntegrationError.noActiveLinkConsumer
            completion(.failure(error))
            return
        }

        let verificationController = LinkVerificationController(
            mode: .modal,
            linkAccount: linkAccount,
            configuration: configuration,
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
    /// - Parameter completion: A closure that is called when the user has selected a payment method or canceled the sheet. If the user selects a payment method, the `paymentMethodPreview` will be updated accordingly.
    @_spi(STP) public func collectPaymentMethod(
        from presentingViewController: UIViewController,
        with email: String?,
        completion: @escaping () -> Void
    ) {
        var configuration = self.configuration
        configuration.defaultBillingDetails.email = email

        // TODO: We need a way to override Link's default primary button label, since we don't want to show "Pay $xx.xx" even for payment mode.
        print("Presenting Link wallet for \(mode)")

        presentingViewController.presentNativeLink(
            selectedPaymentDetailsID: selectedPaymentDetails?.stripeID,
            linkAccount: linkAccount,
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper
        ) { [weak self] confirmOption, shouldClearSelection in
            guard let confirmOption else {
                if shouldClearSelection {
                    self?.internalPaymentOption = nil
                }
                completion()
                return
            }

            self?.internalPaymentOption = .link(option: confirmOption)
            completion()
        }
    }

    /// Creates a [STPPaymentMethod] from the selected Link payment method preview.
    ///
    /// - Parameter completion: A closure that is called with the result of the payment method creation. It returns a `STPPaymentMethod` if successful, or an error if the payment method could not be created.
    @_spi(STP) public func createPaymentMethod(completion: @escaping (Result<STPPaymentMethod, Error>) -> Void) {
        guard let selectedPaymentDetails else {
            completion(.failure(IntegrationError.noPaymentMethodSelected))
            return
        }

        guard let linkAccount = LinkAccountContext.shared.account, let consumerSessionClientSecret = linkAccount.currentSession?.clientSecret else {
            completion(.failure(IntegrationError.noActiveLinkConsumer))
            return
        }

        let clientAttributionMetadata: STPClientAttributionMetadata = intent.clientAttributionMetadata(elementsSessionConfigId: elementsSession.sessionID)

        if elementsSession.linkPassthroughModeEnabled {
            createPaymentMethodInPassthroughMode(
                paymentDetails: selectedPaymentDetails,
                consumerSessionClientSecret: consumerSessionClientSecret,
                clientAttributionMetadata: clientAttributionMetadata,
                completion: completion
            )
        } else {
            createPaymentMethodInPaymentMethodMode(
                paymentDetails: selectedPaymentDetails,
                linkAccount: linkAccount,
                clientAttributionMetadata: clientAttributionMetadata,
                completion: completion
            )
        }
    }

    // MARK: - Private methods

    private func createPaymentMethodInPassthroughMode(
        paymentDetails: ConsumerPaymentDetails,
        consumerSessionClientSecret: String,
        clientAttributionMetadata: STPClientAttributionMetadata,
        completion: @escaping (Result<STPPaymentMethod, Error>) -> Void
    ) {
        // TODO: These parameters aren't final
        apiClient.sharePaymentDetails(
            for: consumerSessionClientSecret,
            id: paymentDetails.stripeID,
            consumerAccountPublishableKey: nil,
            allowRedisplay: nil,
            cvc: paymentDetails.cvc,
            expectedPaymentMethodType: nil,
            billingPhoneNumber: nil,
            clientAttributionMetadata: clientAttributionMetadata
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
        clientAttributionMetadata: STPClientAttributionMetadata,
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
                paymentMethodParams.clientAttributionMetadata = clientAttributionMetadata
                let paymentMethod = try await apiClient.createPaymentMethod(
                    with: paymentMethodParams,
                    additionalPaymentUserAgentValues: []
                )
                completion(.success(paymentMethod))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func loadElementsSession(
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) async throws -> PaymentSheetLoader.LoadResult {
        // Always load as setup mode, even if the merchant specifies another mode.
        let intentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .setup(
                currency: nil,
                setupFutureUsage: .offSession
            ),
            confirmHandler: { _, _, intentCreationCallback in
                stpAssertionFailure("The confirmHandler is not expected to be called in the LinkController.")
                intentCreationCallback(.success(PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT))
            }
        )

        let result = try await PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfiguration),
            configuration: configuration,
            analyticsHelper: analyticsHelper,
            // TODO: Add a non-logging integration shape or something
            integrationShape: .complete
        )

        return result
    }

    private static func lookupConsumer(
        email: String,
        linkAccountService: any LinkAccountServiceProtocol,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        linkAccountService.lookupAccount(
            withEmail: email,
            // TODO: Check that this is the right email source to pass in
            emailSource: .customerEmail,
            // TODO: Confirm which value to pass here to not cause experiment issues
            doNotLogConsumerFunnelEvent: false,
            completion: completion
        )
    }

    @objc
    private func onLinkAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let linkAccount = notification.object as? PaymentSheetLinkAccount
            self?.linkAccount = linkAccount
        }
    }
}

@_spi(STP) public extension LinkController {

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter apiClient: The `STPAPIClient` instance for this controller. Defaults to `.shared`.
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Parameter appearance: Link UI-specific appearance overrides. If not specified, `PaymentSheet.Configuration` defaults are used.
    /// - Returns: A `LinkController` if successful, or throws an error if the creation failed.
    static func create(
        apiClient: STPAPIClient = .shared,
        mode: LinkController.Mode,
        appearance: LinkAppearance? = nil
    ) async throws -> LinkController {
        return try await withCheckedThrowingContinuation { continuation in
            create(apiClient: apiClient, mode: mode, appearance: appearance) { result in
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
    /// - Returns: A `VerificationResult` indicating whether verification was completed or canceled.
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
    /// - Returns: A `PaymentMethodPreview` if the user selected a payment method, or `nil` otherwise.
    func collectPaymentMethod(from presentingViewController: UIViewController, with email: String?) async -> LinkController.PaymentMethodPreview? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.collectPaymentMethod(from: presentingViewController, with: email) { [weak self] in
                    guard let self else { return }
                    continuation.resume(returning: self.paymentMethodPreview)
                }
            }
        }
    }

    /// Creates a [STPPaymentMethod] from the selected Link payment method preview.
    /// - Returns: A `STPPaymentMethod` if successful, or throws an error if the payment method could not be created.
    func createPaymentMethod() async throws -> STPPaymentMethod {
        return try await withCheckedThrowingContinuation { continuation in
            createPaymentMethod { result in
                switch result {
                case .success(let paymentMethod):
                    continuation.resume(returning: paymentMethod)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
