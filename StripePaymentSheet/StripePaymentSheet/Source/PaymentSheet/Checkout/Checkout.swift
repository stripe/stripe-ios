//
//  Checkout.swift
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
/// let checkout = try await Checkout(configuration: .init(clientSecret: "cs_xxx_secret_yyy"))
/// print(checkout.session)
/// ```
///
/// The async initializer loads the session from Stripe before returning.
///
/// Observe loading state and session changes with ``isLoading`` and ``session``
/// (published via `ObservableObject`).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class Checkout: ObservableObject {
    // MARK: - Public Properties

    /// The current loading state of the checkout session.
    ///
    /// After initialization this is always ``false``. It transitions to ``true``
    /// while a mutation is in flight.
    @Published public internal(set) var isLoading: Bool = false

    /// The Checkout Session, updated from Stripe after every mutation.
    @Published public private(set) var session: Session {
        didSet {
            nonisolatedSession = session
            // Just some notes: Setting session causes the publisher to fire even when it didn't change.
            // AFAICT that's okay, deduping sees like a minor optimization to slightly reduce the amount of UI updates.
        }
    }

    /// The configuration supplied at initialization.
    public let configuration: Configuration

    // MARK: - Internal Properties

    /// The PaymentElement for this Checkout instance.
    private(set) var paymentElement: PaymentElement!

    /// The ExpressCheckoutElement for this Checkout instance.
    private var expressCheckoutElement: ExpressCheckoutElement?

    /// The CurrencySelectorElement for this Checkout instance, when Adaptive Pricing is available.
    private var currencySelectorElement: CurrencySelectorElement?

    /// The ShippingAddressElement for this Checkout instance.
    private let shippingAddressElement: ShippingAddressElement

    // TODO(gbirch) TODO(porter) remove this nonisolatedSession
    //  once MPE is properly MainActor isolated
    /// A snapshot of the current ``session`` accessible from non-MainActor contexts.
    ///
    /// Marked `nonisolated(unsafe)` because PaymentSheet internals read this from non-MainActor
    /// contexts. This is safe: reads only occur after the session is loaded and while the payment
    /// UI is presented, a window during which no mutations occur. Writes are always on MainActor
    /// because they go through `Checkout`'s MainActor-isolated mutation methods.
    nonisolated(unsafe) private(set) var nonisolatedSession: Session!

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
            //  isLoading to true. We avoid setting it if the queue
            //  was already non-empty to prevent duplicate loading emissions.
            if !pendingOperations.isEmpty && !isLoading {
                isLoading = true
            }

            // If the queue has gone from non-empty to empty, we set
            //  isLoading to false. There shouldn't be a situation in
            //  which the isLoading is already false, but we check just in case.
            if pendingOperations.isEmpty && isLoading {
                isLoading = false
            }
        }
    }

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
                adaptivePricingAllowed: configuration.adaptivePricing.allowed
            )
            let loadedSession = apiResponse.makePublicSession()
            self.session = loadedSession
            self.nonisolatedSession = loadedSession // temporary hack

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
            self.shippingAddressElement = ShippingAddressElement(
                configuration: configuration.shippingAddressElement,
                initialShippingAddress: defaultShippingAddress ?? loadedSession.shippingAddress,
                allowedCountries: loadedSession.allowedShippingCountries,
                apiClient: configuration.apiClient,
                useAutocompleteEndpoints: loadedSession.elementsSession.shouldUseAutocompleteProxyEndpoints
            )
            let normalizedDefaultShippingAddress: Session.ShippingAddress?
            if defaultShippingAddress != nil {
                normalizedDefaultShippingAddress = await shippingAddressElement.normalizedInitialShippingAddress()
            } else {
                normalizedDefaultShippingAddress = nil
            }

            // Apply the normalized address before initializing elements that read from the session.
            try await applyDefaults(shippingAddress: normalizedDefaultShippingAddress)

            // Load remaining elements
            self.paymentElement = try await PaymentElement(checkout: self)
            let sessionSource = CheckoutSessionSource(initialSession: session, sessionPublisher: $session)
            self.expressCheckoutElement = ExpressCheckoutElement(
                sessionSource: sessionSource,
                configuration: configuration,
                delegate: self
            )
            if configuration.adaptivePricing.allowed {
                self.currencySelectorElement = await CurrencySelectorElement(
                    sessionSource: sessionSource,
                    configuration: configuration.currencySelectorElement,
                    delegate: self
                )
            }

        } catch {
            throw CheckoutError.apiError(message: error.nonGenericDescription)
        }
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
    ///   to a country-only region, pass a ``Checkout.Address`` with just the country.
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

    /// Sets the shipping address for this checkout.
    ///
    /// The address is stored locally and merged into PaymentSheet configuration
    /// when presenting payment UI. If automatic tax is enabled and the tax
    /// address source is "shipping", the address is also sent to the server to
    /// compute updated tax amounts.
    ///
    /// - Parameters:
    ///   - name: The customer's full name.
    ///   - address: The shipping address to set. To reset tax computation
    ///     to a country-only region, pass a ``Checkout.Address`` with just the country.
    /// - Throws: ``CheckoutError`` if the session is not open, or if
    ///   the server request fails.
    public func updateShippingAddress(
        name: String? = nil,
        address: Address
    ) async throws {
        if let allowedCountries = session.allowedShippingCountries,
           !allowedCountries.contains(address.country) {
            throw CheckoutError.invalidShippingCountry(countryCode: address.country)
        }
        let shippingAddress = Session.ShippingAddress(name: name, address: address)
        guard session.shippingAddress != shippingAddress else { return }
        if session.shouldSendTaxRegion(for: "shipping") {
            try await performUpdate(
                .setTaxRegion(address),
                shippingAddress: .newValue(shippingAddress)
            )
        } else {
            try await performUpdate(shippingAddress: .newValue(shippingAddress))
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
                    adaptivePricingAllowed: self.configuration.adaptivePricing.allowed
                )
            } catch {
                throw CheckoutError.apiError(message: error.nonGenericDescription)
            }
            try await self.commitSession(refreshedCheckoutSession)
        }
    }

    // MARK: - Element methods

    /// Returns the PaymentElement for this Checkout instance.
    public func getPaymentElement() -> PaymentElement {
        return paymentElement
    }

    /// Returns the ExpressCheckoutElement for this Checkout instance.
    public func getExpressCheckoutElement() -> ExpressCheckoutElement? {
        return expressCheckoutElement
    }

    /// Returns the CurrencySelectorElement when Adaptive Pricing is available for this Checkout instance.
    public func getCurrencySelectorElement() -> CurrencySelectorElement? {
        return currencySelectorElement
    }

    /// Returns the ShippingAddressElement for this Checkout instance.
    public func getShippingAddressElement() -> ShippingAddressElement {
        return shippingAddressElement
    }

    // MARK: - Confirm

    /// Use this method to confirm the Checkout Session.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window (not compatible with multi-scene apps).
    /// - Returns: A `ConfirmResult` enum - either succeeded, canceled, or failed.
    public func confirm(from presentingViewController: UIViewController? = nil) async -> ConfirmResult {
        guard let presentingViewController = presentingViewController ?? UIWindow.visibleViewController else {
            let errorMessage = "Checkout.confirm(from:) could not find a presenting view controller."
            assertionFailure(errorMessage)
            return .failed(PaymentSheetError.integrationError(nonPIIDebugDescription: errorMessage))
        }

        guard sessionIsOpen else {
            return .failed(PaymentSheetError.integrationError(nonPIIDebugDescription: "Checkout.confirm(from:) cannot confirm a Checkout Session that is no longer open."))
        }

        guard pendingOperations.isEmpty else {
            return .failed(PaymentSheetError.integrationError(nonPIIDebugDescription: "Checkout.confirm(from:) was called while the Checkout Session is still loading. Wait until Checkout.isLoading is false."))
        }

        guard let confirmationContext = confirmationContext(for: paymentElement) else {
            return .failed(PaymentSheetError.confirmingWithInvalidPaymentOption)
        }
        let authenticationContext = AuthenticationContext(
            presentingViewController: presentingViewController,
            appearance: confirmationContext.configuration.appearance
        )

        do {
            let confirmResult = try await enqueueSessionUpdate {
                let result = await Self.confirm(
                    checkout: self,
                    confirmationContext: confirmationContext,
                    authenticationContext: authenticationContext,
                    paymentHandler: self.paymentHandler
                )
                if let checkoutSessionResponse = result.checkoutSessionResponse {
                    try await self.commitSession(checkoutSessionResponse)
                }
                return result
            }
            _ = confirmResult
            // TODO: Map the internal confirm result into `ConfirmResult`.
            return .canceled
        } catch {
            return .failed(error)
        }
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

extension Checkout {
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
extension Checkout {
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
