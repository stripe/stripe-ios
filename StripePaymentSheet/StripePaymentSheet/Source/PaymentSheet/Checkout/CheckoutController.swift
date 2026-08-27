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

/// Manages a Checkout Session lifecycle.
///
/// ```swift
/// let checkout = try await CheckoutController(configuration: .init(clientSecret: "cs_xxx_secret_yyy"))
/// print(checkout.session)
/// ```
///
/// The async initializer loads the session from Stripe before returning.
///
/// Observe loading state and session changes with ``isUpdating`` and ``session``
/// (published via `ObservableObject`).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class CheckoutController: ObservableObject {
    // MARK: - Public Properties

    /// True when the session is being updated.
    /// Use this to disable interactive UI e.g. your buy button.
    @Published public internal(set) var isUpdating: Bool = false

    /// The Checkout Session, updated from Stripe after every mutation.
    @Published public private(set) var session: Session

    /// The configuration supplied at initialization.
    let configuration: Configuration

    // MARK: - Internal Properties

    /// The PaymentElement for this CheckoutController instance.
    private(set) var paymentElement: PaymentElement!

    /// The ExpressCheckoutElement for this CheckoutController instance.
    private var expressCheckoutElement: ExpressCheckoutElement?

    /// The CurrencySelectorElement for this CheckoutController instance, when Adaptive Pricing is available.
    private var currencySelectorElement: CurrencySelectorElement?

    /// The ShippingAddressElement for this CheckoutController instance.
    private let shippingAddressElement: ShippingAddressElement

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

    /// Default timeout used by ``awaitPendingOperations(timeout:)``.
    nonisolated static let defaultPendingOperationsTimeout: TimeInterval = 30

    /// Timeout enforced on the merchant's closure in ``runServerUpdate(_:)``.
    nonisolated static let serverUpdateTimeout: TimeInterval = 20

    // MARK: - Initialization

    /// Loads a Checkout Session from Stripe and returns a ready-to-use instance.
    ///
    /// - Parameter configuration: Configuration options for the checkout.
    /// - Throws: ``CheckoutError`` if the client secret is invalid or the session cannot be loaded.
    public init(configuration: Configuration) async throws {
        let clientSecret = configuration.clientSecret
        guard !clientSecret.isEmpty else {
            throw CheckoutError.invalidClientSecret
        }
        #if DEBUG
        configuration.validateReturnURL()
        #endif
        self.clientSecret = clientSecret
        self.configuration = configuration
        self.apiClient = configuration.apiClient

        let sessionId = Self.extractSessionId(from: clientSecret)
        do {
            // Call /init
            let apiResponse = try await configuration.apiClient.initCheckoutSession(
                checkoutSessionId: sessionId,
                adaptivePricingAllowed: configuration.currencySelectorElement != nil
            )
            let loadedSession = apiResponse.makePublicSession()
            self.session = loadedSession

            // Element initialization is intentionally sequential:

            // 1. Initialize SAE so that its form can normalize the raw default shipping address before it is applied to the session
            let (shippingAddressElement, normalizedDefaultShippingAddress) = await Self.makeShippingAddressElement(
                configuration: configuration,
                session: loadedSession
            )
            self.shippingAddressElement = shippingAddressElement
            self.shippingAddressElement.delegate = self

            try await applyDefaults(shippingAddress: normalizedDefaultShippingAddress)

            // 2.
            // PaymentElement reads from the session during initialization, then updates it with the
            // initial payment option and may sync its billing address to recalculate tax. It must finish
            // before creating the session source so the remaining elements receive the resulting session
            // as their initial value.
            self.paymentElement = try await PaymentElement(checkout: self)

            // Create the session source that we can pass to the reaminign elements, which do not need to mutate the session.
            // Elements past this point can be initialized in any order since they do not mutate the session.
            let sessionSource = CheckoutSessionSource(initialSession: session, sessionPublisher: $session)

            // 3. ECE
            self.expressCheckoutElement = ExpressCheckoutElement(
                sessionSource: sessionSource,
                configuration: configuration.expressCheckoutElement,
                delegate: self
            )

            // 4. CSE
            if let currencySelectorConfiguration = configuration.currencySelectorElement {
                self.currencySelectorElement = await CurrencySelectorElement(
                    sessionSource: sessionSource,
                    configuration: currencySelectorConfiguration,
                    delegate: self
                )
            }
        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
    }

    private static func makeShippingAddressElement(
        configuration: Configuration,
        session: Session
    ) async -> (ShippingAddressElement, Session.ShippingAddress?) {
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

        // Initialize the SAE with the raw default so its form can normalize the address.
        let shippingAddressElement = ShippingAddressElement(
            configuration: configuration.shippingAddressElement,
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

    /// Applies a promotion code to the session.
    /// - Parameter code: The promotion code to apply.
    /// - Throws: ``CheckoutError`` if applying the promotion code fails.
    public func applyPromotionCode(_ code: String) async throws {
        try await performUpdate(.setPromotionCode(code))
    }

    /// Removes the currently applied promotion code.
    /// - Throws: ``CheckoutError`` if removing the promotion code fails.
    public func removePromotionCode() async throws {
        try await performUpdate(.setPromotionCode(""))
    }

    // MARK: - Payment Option

    /// Clears the currently selected payment option.
    public func clearPaymentOption() {
        paymentElement?.clearPaymentOption()
    }

    // MARK: - Addresses

    /// Updates the billing tax region for this checkout, if billing is the session's tax address source.
    ///
    /// If automatic tax is enabled and the tax address source is "billing",
    /// the address is sent to the server to compute updated tax amounts.
    ///
    /// - Parameter address: The billing address to use for tax calculation. To reset tax computation
    ///   to a country-only region, pass a ``CheckoutController.Address`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    func updateBillingTaxRegionIfNecessary(
        address: Address,
        canUpdateWhileSheetPresented: Bool = false
    ) async throws {
        guard session.shouldSendTaxRegion(for: "billing") else {
            return
        }
        try await performUpdate(.setTaxRegion(address), canUpdateWhileSheetPresented: canUpdateWhileSheetPresented)
    }

    /// Sets or clears the shipping address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "shipping", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameters:
    ///   - name: The customer's full name.
    ///   - address: The shipping address to set, or `nil` to clear it. To reset tax computation
    ///     to a country-only region, pass a ``CheckoutController.Address`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    public func updateShippingAddress(
        name: String? = nil,
        address: Address?
    ) async throws {
        if let address,
           let allowedCountries = session.allowedShippingCountries,
           !allowedCountries.contains(address.country) {
            throw CheckoutError.invalidShippingCountry(countryCode: address.country)
        }
        let shippingAddress = address.map { Session.ShippingAddress(name: name, address: $0) }
        let shouldSendTaxRegion = session.shouldSendTaxRegion(for: "shipping")
        let shouldPerform: @MainActor () -> Bool = {
            self.session.shippingAddress != shippingAddress || (address == nil && shouldSendTaxRegion)
        }
        if pendingOperations.isEmpty && !shouldPerform() { return }
        if shouldSendTaxRegion {
            try await performUpdate(
                .setTaxRegion(address),
                shippingAddress: .newValue(shippingAddress),
                shouldPerform: shouldPerform
            )
        } else {
            try await performUpdate(
                shippingAddress: .newValue(shippingAddress),
                shouldPerform: shouldPerform
            )
        }
    }

    // MARK: - Server Updates

    /// Runs an async function that calls your server to update the Checkout Session,
    /// then automatically refreshes ``session`` with the latest session data.
    ///
    /// A 20-second timeout is enforced. If `updateFunction` doesn't complete
    /// within 20 seconds, this method throws ``CheckoutError.timedOut``.
    ///
    /// - Parameter updateFunction: An async throwing function that makes a request
    ///   to your server to update the Checkout Session.
    /// - Throws: ``CheckoutError`` if the function times out, the session is not
    ///   open, or the refresh fails.
    public func runServerUpdate(
        _ updateFunction: @escaping () async throws -> Void
    ) async throws {
        try await enqueueSessionUpdate {
            try self.requireSheetNotPresented()
            let result = await withTimeout(Self.serverUpdateTimeout) {
                try await updateFunction()
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
                    adaptivePricingAllowed: self.configuration.currencySelectorElement != nil
                )
            } catch {
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
            try await self.commitSession(refreshedCheckoutSession)
        }
    }

    // MARK: - Element methods

    /// Returns the PaymentElement for this CheckoutController instance.
    public func getPaymentElement() -> PaymentElement {
        return paymentElement
    }

    /// Returns the ExpressCheckoutElement for this CheckoutController instance.
    public func getExpressCheckoutElement() -> ExpressCheckoutElement? {
        return expressCheckoutElement
    }

    /// Returns Currency Selector Element when it was configured and Adaptive
    /// Pricing is available for this Checkout instance.
    public func getCurrencySelectorElement() -> CurrencySelectorElement? {
        return currencySelectorElement
    }

    /// Returns the ShippingAddressElement for this CheckoutController instance.
    public func getShippingAddressElement() -> ShippingAddressElement {
        return shippingAddressElement
    }

    // MARK: - Confirm

    /// Use this method to confirm the Checkout Session.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window (not compatible with multi-scene apps).
    /// - Returns: A `ConfirmResult` enum - either succeeded, canceled, or failed.
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
        /// The Checkout Session succeeded.
        /// - Parameter paymentStatus: The payment status of the Checkout Session, one of `paid`, `unpaid`, or `no_payment_required`.
        case succeeded(paymentStatus: Session.Status.PaymentStatus)
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

        if let billingDetails = defaults.billingDetails,
           let address = billingDetails.address {
            try await updateBillingTaxRegionIfNecessary(address: address)
        }

        if let shippingAddress {
            do {
                try await updateShippingAddress(
                    name: shippingAddress.name,
                    address: shippingAddress.address
                )
            } catch CheckoutError.invalidShippingCountry {
                // Treat a default address with a disallowed country as nil.
            } catch {
                throw error
            }
        }
    }
}
// MARK: - Internal session setters
// These exist here because `session` is private(set) to enforce that session can only be mutated through these sanctioned paths.
// Setting the session should generally only be done via `commitSession` to avoid putting us into an inconsistent state e.g. without using commitSession, MPE is not aware of the updated session.
extension CheckoutController {
    /// Replaces the current session from an API response, applies local state, and updates Checkout elements.
    ///
    /// Existing local state is preserved unless explicitly replaced.
    func commitSession(
        _ apiResponse: PaymentPagesAPIResponse? = nil,
        shippingAddress: SessionFieldUpdate<Session.ShippingAddress> = .keepOldValue,
        paymentOption: SessionFieldUpdate<Session.PaymentOptionDisplayData> = .keepOldValue
    ) async throws {
        let newSession = apiResponse?.makePublicSession() ?? session
        session = newSession.makeCopyOverriding(
            shippingAddress: .newValue(
                shippingAddress.resolved(currentValue: session.shippingAddress)
            ),
            paymentOption: .newValue(
                paymentOption.resolved(currentValue: session.paymentOption)
            )
        )

        // === Update Payment Element and all other asynchronously updated elements ==
        try await paymentElement?.update(checkout: self)
    }

    /// - Warning: See `commitSession` for what this method *doesn't* do. That includes updating Checkout elements.
    func dangerouslySetSessionDirectly(_ session: Session) {
        self.session = session
    }
}
