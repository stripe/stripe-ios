//
//  CheckoutController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Combine
import Foundation
@_spi(STP) import StripeApplePay
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import UIKit

/// Use this class to build a [Checkout elements](todo) integration.
/// It manages a CheckoutSession object and UI elements (e.g. PaymentElement, ShippingAddressElement).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class CheckoutController: ObservableObject {
    // MARK: - Public Properties

    /// True when the session is being updated.
    /// Use this to disable interactive UI e.g. your buy button.
    @Published public internal(set) var isUpdating: Bool = false

    /// The Session object is a view of the Checkout Session API object and represents your customer's session in your checkout flow.
    @Published public private(set) var session: Session

    /// The configuration supplied at initialization.
    let configuration: Configuration

    // MARK: - Internal Properties

    /// The PaymentElement for this CheckoutController instance
    private(set) var paymentElement: PaymentElement?

    /// The ExpressCheckoutElement for this CheckoutController instance.
    private var expressCheckoutElement: ExpressCheckoutElement?

    /// The CurrencySelectorElement for this CheckoutController instance, when Adaptive Pricing is available.
    private var currencySelectorElement: CurrencySelectorElement?

    /// The ShippingAddressElement for this CheckoutController instance.
    private let shippingAddressElement: ShippingAddressElement?

    private(set) var confirmationChallenge: ConfirmationChallenge?

    let clientSecret: String
    let apiClient: STPAPIClient
    lazy var paymentHandler: STPPaymentHandler = STPPaymentHandler(apiClient: apiClient)
    var effectiveMerchantDisplayName: String {
        configuration.merchantDisplayName ?? session.businessName ?? Bundle.displayName ?? ""
    }

    /// Serial queue of in-flight session updates. Each task waits for the previous task before running.
    var pendingOperations: [Task<Void, Error>] = [] {
        didSet {
            // If the queue has gone from empty to non-empty, we set
            //  isUpdating to true. We avoid setting it if the queue
            //  was already non-empty to prevent duplicate loading emissions.
            if !pendingOperations.isEmpty && !isUpdating {
                isUpdating = true
            }

            // If the queue has gone from non-empty to empty, we set
            //  isUpdating to false. There shouldn't be a situation in
            //  which the isUpdating is already false, but we check just in case.
            if pendingOperations.isEmpty && isUpdating {
                isUpdating = false
            }
        }
    }

    /// Guards confirmation across Payment Element and Express Checkout entry points.
    var confirmationInProgress = false

    /// The last tax region successfully sent by this CheckoutController.
    var currentTaxRegion: Address?

    /// Default timeout used by ``awaitPendingOperations(timeout:)``.
    nonisolated static let defaultPendingOperationsTimeout: TimeInterval = 30

    /// Timeout enforced on the merchant's closure in ``runServerUpdate(_:)``.
    nonisolated static let serverUpdateTimeout: TimeInterval = 20

    // MARK: - Initialization

    /// Initializes a CheckoutController instance
    public init(configuration: Configuration) async throws {
        // Validations
        guard !configuration.clientSecret.isEmpty else {
            throw CheckoutError.invalidClientSecret
        }
        #if DEBUG
        configuration.validateReturnURL()
        #endif
        assert(!configuration.apiClient.publishableKeyIsUserKey, "Dashboard isn't supported.")
        self.clientSecret = configuration.clientSecret
        self.configuration = configuration
        self.apiClient = configuration.apiClient

        do {
            // 1. Initialize the session
            let session = try await CheckoutControllerLoader.load(configuration: configuration)
            self.session = session

            // 2. Initialize SAE first so it can normalize the default shipping address before we apply it to the session.
            let (shippingAddressElement, normalizedDefaultShippingAddress) = await Self.makeShippingAddressElement(
                configuration: configuration,
                session: session
            )
            self.shippingAddressElement = shippingAddressElement
            self.shippingAddressElement?.delegate = self

            // 3. Apply defaults; note this can trigger tax updates that change the session total.
            try await applyDefaults(shippingAddress: normalizedDefaultShippingAddress)

            // 4. The session is now finalized - do post-session-change stuff
            let handleSessionChangeResult = CheckoutControllerLoader.handleSessionChange(checkout: self)
            confirmationChallenge = handleSessionChangeResult.confirmationChallenge
            // 4a. Initialize PE
            if let paymentElementInitParameters = handleSessionChangeResult.paymentElement {
                self.paymentElement = try PaymentElement(
                    checkout: self,
                    flowControllerInitParameters: paymentElementInitParameters.flowController,
                    embeddedPaymentElementInitParameters: paymentElementInitParameters.embedded
                )
                // The initial payment selection's billing address may require another tax update.
                try await syncBillingAddress(from: paymentElement?.embeddedPaymentElement._paymentOption?.checkoutBillingDetails)
            }

            // 4b. Initialize remaining elements
            let sessionSource = CheckoutSessionSource(initialSession: session, sessionPublisher: $session)

            if let expressCheckoutElementConfiguration = configuration.expressCheckoutElement {
                self.expressCheckoutElement = ExpressCheckoutElement(
                    sessionSource: sessionSource,
                    configuration: expressCheckoutElementConfiguration,
                    delegate: self,
                    apiClient: apiClient
                )
            }

            if let currencySelectorConfiguration = configuration.currencySelectorElement {
                self.currencySelectorElement = await CurrencySelectorElement(
                    sessionSource: sessionSource,
                    configuration: currencySelectorConfiguration,
                    delegate: self
                )
            }
        } catch {
            // TODO: Don't overwrite errors, vend them directly.
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    private static func makeShippingAddressElement(
        configuration: Configuration,
        session: Session
    ) async -> (ShippingAddressElement?, Session.ShippingAddress?) {
        let defaultShippingAddress: Session.ShippingAddress?
        if let shippingDetails = configuration.defaults.shippingDetails,
           let address = shippingDetails.address {
            defaultShippingAddress = Session.ShippingAddress(
                name: shippingDetails.name,
                address: address
            )
        } else {
            defaultShippingAddress = nil
        }

        guard let shippingAddressElementConfiguration = configuration.shippingAddressElement else {
            return (nil, defaultShippingAddress)
        }

        // Initialize the SAE with the raw default so its form can normalize the address.
        let shippingAddressElement = ShippingAddressElement(
            configuration: shippingAddressElementConfiguration,
            userInterfaceStyle: configuration.userInterfaceStyle,
            initialShippingAddress: defaultShippingAddress ?? session.shippingAddress,
            allowedCountries: session.allowedShippingCountries,
            checkoutSessionId: session.id,
            apiClient: configuration.apiClient,
            useAutocompleteEndpoints: session.elementsSession.shouldUseAutocompleteProxyEndpoints
        )
        let normalizedDefaultShippingAddress: Session.ShippingAddress?
        if defaultShippingAddress != nil {
            normalizedDefaultShippingAddress = await shippingAddressElement.normalizedInitialShippingAddress()
        } else {
            normalizedDefaultShippingAddress = nil
        }

        return (shippingAddressElement, normalizedDefaultShippingAddress)
    }

    // MARK: - Promotion Codes

    /// Use this method to apply a promotion code that your customer enters.
    public func applyPromotionCode(_ promotionCode: String) async throws {
        try await performQueuedUpdate(.setPromotionCode(promotionCode))
    }

    /// Use this method to remove the currently applied promotion code, if applicable.
    public func removePromotionCode() async throws {
        try await performQueuedUpdate(.setPromotionCode(""))
    }

    // MARK: - Payment Option

    /// Clears the currently selected payment option.
    public func clearPaymentOption() async throws {
        try await paymentElement?.clearPaymentOption()
    }

    // MARK: - Email

    /// Use this method to update the Customer's email address.
    /// - Important: You cannot use this method if the Checkout Session was created with
    ///   `customer_email` or a Customer with an email. Those emails are immutable.
    public func updateEmail(_ email: String?) async throws {
        try await enqueueSessionUpdate {
            guard self.canSetLocalEmail() else { return }
            guard self.session.localState.email != email else { return }
        // TODO: Refresh Link account lookup when the email changes.
            try await self.performUnqueuedUpdate { localState in
                localState.email = email
            }
        }
    }

    // MARK: - Addresses

    /// Updates the billing tax region for this checkout, if billing is the session's tax address source.
    ///
    /// If automatic tax is enabled and the tax address source is "billing",
    /// the address is sent to the server to compute updated tax amounts.
    ///
    /// - Parameter address: The billing address to use for tax calculation. Pass `nil` when
    ///   removing the selected payment option's billing address.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    func updateBillingTaxRegionIfNecessary(
        address: Address?,
        canUpdateWhileSheetPresented: Bool = false
    ) async throws {
        guard session.shouldSendTaxRegion(for: "billing") else { return }
        try await performQueuedUpdate(
            .setTaxRegion(address),
            canUpdateWhileSheetPresented: canUpdateWhileSheetPresented
        )
    }

    /// Use this method to update the Customer's shipping address.
    public func updateShippingAddress(
        name: String?,
        address: Address?
    ) async throws {
        guard let address else {
            try await clearShippingAddress()
            return
        }
        if let allowedCountries = session.allowedShippingCountries,
           !allowedCountries.contains(address.country.uppercased()) {
            throw CheckoutError.invalidShippingCountry(countryCode: address.country)
        }
        let shippingAddress = Session.ShippingAddress(name: name, address: address)
        guard session.shippingAddress != shippingAddress else { return }
        if session.shouldSendTaxRegion(for: "shipping") {
            try await performQueuedUpdate(.setTaxRegion(address)) {
                $0.shippingAddress = shippingAddress
            }
        } else {
            try await performQueuedUpdate {
                $0.shippingAddress = shippingAddress
            }
        }
    }

    private func clearShippingAddress() async throws {
        guard session.shippingAddress != nil else { return }
        if session.shouldSendTaxRegion(for: "shipping") {
            try await performQueuedUpdate(.setTaxRegion(nil)) {
                $0.shippingAddress = nil
            }
        } else {
            // No server update is needed when shipping isn't the tax address source.
            try await performQueuedUpdate {
                $0.shippingAddress = nil
            }
        }
    }

    // MARK: - Server Updates

    /// Use this method to wrap an async closure that makes a request to your server to update the Checkout Session.
    /// The closure must return when your server has completed the update or throw an error if the update fails.
    public func runServerUpdate(
        _ update: @escaping () async throws -> Void
    ) async throws {
        try await enqueueSessionUpdate {
            try self.requireSheetNotPresented()
            let result = await withTimeout(Self.serverUpdateTimeout) {
                try await update()
            }
            if case .failure(let error) = result {
                if error is TimeoutError {
                    throw CheckoutError.timedOut
                }
                throw CheckoutError.apiError(message: error.localizedDescription)
            }
            let sessionId = Self.extractSessionId(from: self.clientSecret)
            let refreshedCheckoutSession: PaymentPagesAPIResponse
            do {
                refreshedCheckoutSession = try await self.apiClient.initCheckoutSession(
                    checkoutSessionId: sessionId,
                    clientSecret: self.clientSecret,
                    adaptivePricingAllowed: self.configuration.currencySelectorElement != nil
                )
            } catch {
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
            self.commitSession(refreshedCheckoutSession)
            self.updateForSessionChange()
        }
    }

    // MARK: - Element methods

    /// Returns a PaymentElement instance.
    /// Multiple invocations return the same instance.
    public func getPaymentElement() -> PaymentElement {
        assert(configuration.paymentElement != nil, "Set Configuration.paymentElement before calling getPaymentElement().")
        stpAssert(paymentElement != nil, "PaymentElement should be initialized when Configuration.paymentElement is set.")
        return paymentElement!
    }

    /// Returns the ExpressCheckoutElement for this CheckoutController instance.
    public func getExpressCheckoutElement() -> ExpressCheckoutElement {
        assert(configuration.expressCheckoutElement != nil, "Set Configuration.expressCheckoutElement before calling getExpressCheckoutElement().")
        stpAssert(expressCheckoutElement != nil, "ExpressCheckoutElement should be initialized when Configuration.expressCheckoutElement is set.")
        return expressCheckoutElement!
    }

    /// Returns Currency Selector Element when it was configured and Adaptive
    /// Pricing is available for this Checkout instance.
    public func getCurrencySelectorElement() -> CurrencySelectorElement? {
        assert(
            configuration.currencySelectorElement != nil,
            "Set Configuration.currencySelectorElement before calling getCurrencySelectorElement()."
        )
        return currencySelectorElement
    }

    /// Returns the ShippingAddressElement for this CheckoutController instance.
    public func getShippingAddressElement() -> ShippingAddressElement {
        assert(
            configuration.shippingAddressElement != nil,
            "Set Configuration.shippingAddressElement before initializing the CheckoutController to use ShippingAddressElement."
        )
        return shippingAddressElement!
    }

    // MARK: - Confirm

    /// Use this method to confirm the Checkout Session.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// Returns a ConfirmResult enum - either completed, canceled, or failed.
    public func confirm(from presentingViewController: UIViewController? = nil) async -> ConfirmResult {
        guard let presentingViewController = presentingViewController ?? UIWindow.visibleViewController else {
            let errorMessage = "CheckoutController.confirm(from:) could not find a presenting view controller."
            assertionFailure(errorMessage)
            return .failed(PaymentSheetError.integrationError(nonPIIDebugDescription: errorMessage))
        }

        guard let flow = makeConfirmationFlow(
            for: paymentElement,
            presentingViewController: presentingViewController
        ) else {
            return .failed(PaymentSheetError.confirmingWithInvalidPaymentOption)
        }
        return await confirm(flow)
    }

    /// The result of an attempt to confirm a Checkout Session.
    /// This is a convenience abstraction over the underlying Checkout Session's status and paymentStatus properties.
    public enum ConfirmResult {
        /// The Checkout Session completed.
        /// - Parameter paymentStatus: The payment status of the Checkout Session, one of `paid`, `unpaid`, or `no_payment_required`.
        case completed(paymentStatus: Session.Status.PaymentStatus)
        /// The customer canceled the confirmation attempt.
        case canceled
        /// Confirmation failed with an error.
        case failed(Error)
    }
}

// MARK: - Defaults

extension CheckoutController {
    func applyDefaults(shippingAddress: Session.ShippingAddress?) async throws {
        let defaults = configuration.defaults

        // Apply the default email locally
        if let email = defaults.email,
           canSetLocalEmail() {
            commitSession { localState in
                localState.email = email
            }
        }

        // Update tax from the default billing address, if needed
        if let address = defaults.billingDetails?.address,
           session.shouldSendTaxRegion(for: "billing") {
            let response = try await apiClient.updateCheckoutSession(
                checkoutSessionId: Self.extractSessionId(from: clientSecret),
                clientSecret: clientSecret,
                parameters: SessionUpdate.setTaxRegion(address).parameters
            )
            currentTaxRegion = address
            commitSession(response)
        }

        // Apply the default shipping address
        if let shippingAddress {
            // Check that the shipping country is allowed
            if let allowedCountries = session.allowedShippingCountries,
               !allowedCountries.contains(shippingAddress.address.country.uppercased()) {
                // Treat a default address with a disallowed country as nil.
                return
            }
            guard session.shippingAddress != shippingAddress else { return }

            // Update tax from the default shipping address, if needed
            if session.shouldSendTaxRegion(for: "shipping") {
                let response = try await apiClient.updateCheckoutSession(
                    checkoutSessionId: Self.extractSessionId(from: clientSecret),
                    clientSecret: clientSecret,
                    parameters: SessionUpdate.setTaxRegion(shippingAddress.address).parameters
                )
                currentTaxRegion = shippingAddress.address
                commitSession(response) {
                    $0.shippingAddress = shippingAddress
                }
            } else {
                // No tax update needed; only store the default shipping address locally
                commitSession {
                    $0.shippingAddress = shippingAddress
                }
            }
        }
    }
}
// MARK: - Internal session setters
// These exist here because `session` is private(set) to enforce that session can only be mutated through these sanctioned paths.
// Normal update paths commit the session, then call updateForSessionChange to update derived state and elements.
extension CheckoutController {
    /// Stores an API response and local state without processing the session or updating elements.
    ///
    /// Existing local state is preserved unless explicitly replaced.
    /// TODO: Rename to `setSession` or delete this and just inline, it's unnecessarily complex.
    func commitSession(
        _ apiResponse: PaymentPagesAPIResponse? = nil,
        mutateLocalState: LocalStateMutation = { _ in }
    ) {
        var localState = session.localState
        mutateLocalState(&localState)

        if let apiResponse {
            session = Session(
                apiResponse: apiResponse,
                clientSecret: clientSecret,
                localState: localState,
                configuration: configuration
            )
        } else {
            session.localState = localState
        }
    }

    /// Updates everything necessary after a session change.
    /// Call this after committing a 'normal' session update; not for initialization or confirmation.
    func updateForSessionChange() {
        guard sessionIsOpen else { return }
        let result = CheckoutControllerLoader.handleSessionChange(checkout: self)
        // Update confirmation challenge. I'm not sure if this is necessary, but the intents integration does it too on `update`
        confirmationChallenge = result.confirmationChallenge
        // Update PE
        if let paymentElementInitParameters = result.paymentElement {
            paymentElement?.apply(
                flowControllerInitParameters: paymentElementInitParameters.flowController,
                embeddedPaymentElementInitParameters: paymentElementInitParameters.embedded,
                checkout: self
            )
        }
    }

    /// - Warning: Replaces the entire session without processing it or updating Checkout elements.
    func dangerouslySetSessionDirectly(_ session: Session) {
        self.session = session
    }

    private func canSetLocalEmail() -> Bool {
        guard session.serverEmail == nil else {
            assertionFailure(
                "Email cannot be set locally when the Checkout Session was created with customer_email or a Customer with an email."
            )
            return false
        }
        return true
    }
}
