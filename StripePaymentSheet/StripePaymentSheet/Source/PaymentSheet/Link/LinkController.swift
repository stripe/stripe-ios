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
    private let analyticsHelper: PaymentSheetAnalyticsHelper

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

    /// A preview of the currently selected Link payment method.
    @Published @_spi(STP) public private(set) var paymentMethodPreview: PaymentMethodPreview?

    private init(
        apiClient: STPAPIClient = .shared,
        mode: Mode,
        elementsSession: STPElementsSession,
        intent: Intent,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.apiClient = apiClient
        self.mode = mode
        self.elementsSession = elementsSession
        self.intent = intent
        self.configuration = configuration
        self.analyticsHelper = analyticsHelper
    }

    @_spi(STP) public static var linkIcon: UIImage = Image.link_icon.makeImage()

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Parameter completion: A closure that is called with the result of the creation. It returns a `LinkController` if successful, or an error if the creation failed.
    @_spi(STP) public static func create(
        mode: LinkController.Mode,
        completion: @escaping (Result<LinkController, Error>) -> Void
    ) {
        Task {
            do {
                let configuration = PaymentSheet.Configuration()
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
                    mode: mode,
                    elementsSession: loadResult.elementsSession,
                    intent: loadResult.intent,
                    configuration: configuration,
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
            useMobileEndpoints: elementsSession.linkSettings?.useAttestationEndpoints ?? false,
            sessionID: elementsSession.sessionID
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

    /// Presents the Link sheet to collect a customer's payment method.
    ///
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Parameter email: The email address to pre-fill in the Link sheet. If `nil`, the email field will be empty.
    /// - Parameter completion: A closure that is called when the user has selected a payment method or canceled the sheet. If the user selects a payment method, the `paymentMethodPreview` will be updated accordingly.
    @_spi(STP) public func present(
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

        if elementsSession.linkPassthroughModeEnabled {
            createPaymentMethodInPassthroughMode(
                paymentDetails: selectedPaymentDetails,
                consumerSessionClientSecret: consumerSessionClientSecret,
                completion: completion
            )
        } else {
            createPaymentMethodInPaymentMethodMode(
                paymentDetails: selectedPaymentDetails,
                linkAccount: linkAccount,
                completion: completion
            )
        }
    }

    // MARK: - Private methods

    private func createPaymentMethodInPassthroughMode(
        paymentDetails: ConsumerPaymentDetails,
        consumerSessionClientSecret: String,
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
            billingPhoneNumber: nil
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
        useMobileEndpoints: Bool,
        sessionID: String,
        completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
    ) {
        let linkAccountService = LinkAccountService(
            useMobileEndpoints: useMobileEndpoints,
            sessionID: sessionID
        )

        linkAccountService.lookupAccount(
            withEmail: email,
            // TODO: Check that this is the right email source to pass in
            emailSource: .customerEmail,
            // TODO: Confirm which value to pass here to not cause experiment issues
            doNotLogConsumerFunnelEvent: false,
            completion: completion
        )
    }
}

@_spi(STP) public extension LinkController {

    /// Creates a `LinkController` for the specified `mode`.
    ///
    /// - Parameter mode: The mode in which the Link payment method controller should operate, either `payment` or `setup`.
    /// - Returns: A `LinkController` if successful, or throws an error if the creation failed.
    static func create(mode: LinkController.Mode) async throws -> LinkController {
        return try await withCheckedThrowingContinuation { continuation in
            create(mode: mode) { result in
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
        return try await withCheckedThrowingContinuation { continuation in
            lookupConsumer(with: email) { result in
                switch result {
                case .success(let isExistingLinkConsumer):
                    continuation.resume(returning: isExistingLinkConsumer)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    /// Presents the Link sheet to collect a customer's payment method.
    ///
    /// - Parameter presentingViewController: The view controller from which to present the Link sheet.
    /// - Parameter email: The email address to pre-fill in the Link sheet. If `nil`, the email field will be empty.
    /// - Returns: A `PaymentMethodPreview` if the user selected a payment method, or `nil` otherwise.
    func present(from presentingViewController: UIViewController, with email: String?) async -> LinkController.PaymentMethodPreview? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.present(from: presentingViewController, with: email) { [weak self] in
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
