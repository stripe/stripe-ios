//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// An element that displays wallet buttons (e.g. Apple Pay, Link) for a Checkout Session.
/// Use this to let customers quickly pay with an express payment method without going through a full payment flow.
///
/// - Note: This is a Checkout Sessions-only API.
@_spi(STP)
@MainActor
public final class ExpressCheckoutElement: STPAnalyticsProtocol {
    @_spi(STP) public nonisolated static let stp_analyticsIdentifier = "ExpressCheckoutElement"

    // MARK: - Configuration

    /// Configuration for ``ExpressCheckoutElement``.
    public struct Configuration {
        /// Describes the appearance of the Express Checkout Element.
        public var appearance: PaymentSheet.Appearance = .default

        /// Configuration related to Apple Pay.
        /// If set, the Apple Pay button will be shown when Apple Pay is available.
        public var applePay: PaymentSheet.ApplePayConfiguration?

        /// Configuration related to Link.
        public var link: PaymentSheet.LinkConfiguration = .init()

        /// The URL that Stripe should redirect to after a redirect-based payment method completes.
        /// Required for redirect-based payment methods (e.g. some Link flows).
        public var returnURL: String?

        /// Configuration for how billing details are collected.
        public var billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration()

        /// If `true`, the Apple Pay sheet will show a coupon code field.
        /// Only enable this when your Checkout Session has `allow_promotion_codes: true`.
        public var allowsPromotionCodes: Bool = false

        /// Creates a configuration with default values.
        public init() {}
    }

    // MARK: - Public properties

    /// The delegate to be notified of payment completion.
    public weak var delegate: ExpressCheckoutElementDelegate?

    /// `true` if there are any wallet buttons available to display.
    /// Use this to conditionally show or hide the element in your UI.
    public var hasWallets: Bool {
        return !availableWallets.isEmpty
    }

    // MARK: - Internal properties

    let checkout: Checkout
    let configuration: PaymentSheet.Configuration
    let elementsSession: STPElementsSession
    let availableWallets: [ExpressType]
    let analyticsHelper: PaymentSheetAnalyticsHelper
    private(set) lazy var paymentHandler: STPPaymentHandler = STPPaymentHandler(apiClient: configuration.apiClient)

    var intent: Intent { .checkout(checkout) }

    // MARK: - Initialization

    /// Creates an ``ExpressCheckoutElement`` backed by the given Checkout Session.
    ///
    /// ```swift
    /// var config = ExpressCheckoutElement.Configuration()
    /// config.applePay = .init(
    ///     merchantId: "merchant.com.example",
    ///     merchantCountryCode: "US"
    /// )
    /// let element = try await ExpressCheckoutElement(checkout: checkout, configuration: config)
    /// ```
    ///
    /// - Parameters:
    ///   - checkout: The ``Checkout`` instance backing this element.
    ///   - configuration: Configuration for the element.
    /// - Throws: An error if the element could not be loaded.
    public init(checkout: Checkout, configuration: Configuration) async throws {
        try await checkout.awaitPendingOperations()

        var psConfiguration = configuration.asPaymentSheetConfiguration(apiClient: checkout.apiClient)
        checkout.nonisolatedSession.applyAddressOverrides(to: &psConfiguration)

        AnalyticsHelper.shared.generateSessionID()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: ExpressCheckoutElement.self)
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .flowController, configuration: psConfiguration)

        let (loadResult, _) = try await PaymentSheetLoader.load(
            mode: .checkout(checkout),
            configuration: psConfiguration,
            analyticsHelper: analyticsHelper,
            integrationShape: .flowController
        )

        self.checkout = checkout
        self.configuration = psConfiguration
        self.elementsSession = loadResult.elementsSession
        self.analyticsHelper = analyticsHelper
        self.availableWallets = ExpressCheckoutElement.determineAvailableWallets(
            elementsSession: loadResult.elementsSession,
            configuration: psConfiguration,
            checkoutSession: checkout.nonisolatedSession
        )
    }

    // MARK: - Wallet determination

    private static func determineAvailableWallets(
        elementsSession: STPElementsSession,
        configuration: PaymentSheet.Configuration,
        checkoutSession: Checkout.Session?
    ) -> [ExpressType] {
        // Link cannot collect shipping addresses or apply promo codes, so hide it when the
        // session requires either.
        let linkSupported = !(checkoutSession?.requiresShippingAddress == true)
            && !configuration.allowsPromotionCodes

        var wallets: [ExpressType] = []

        for type in elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "apple_pay":
                if PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration) {
                    wallets.append(.applePay)
                }
            case "link":
                if linkSupported && PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration) {
                    wallets.append(.link)
                }
            default:
                continue
            }
        }

        if linkSupported &&
            elementsSession.linkPassthroughModeEnabled &&
            PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration) &&
            !wallets.contains(.link) {
            wallets.append(.link)
        }

        return wallets
    }
}
