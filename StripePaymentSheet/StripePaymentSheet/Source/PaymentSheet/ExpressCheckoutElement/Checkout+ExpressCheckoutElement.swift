//
//  Checkout+ExpressCheckoutElement.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@_spi(STP)
extension Checkout {

    /// Creates an ``ExpressCheckoutElement`` backed by this Checkout Session.
    ///
    /// The element displays wallet buttons (Apple Pay, Link) that let customers
    /// complete payment without a full payment form. Configure the element via
    /// ``Configuration/expressCheckout`` before calling this method.
    ///
    /// ```swift
    /// var config = Checkout.Configuration()
    /// config.expressCheckout.applePay = .init(
    ///     merchantId: "merchant.com.example",
    ///     merchantCountryCode: "US"
    /// )
    /// let checkout = try await Checkout(clientSecret: clientSecret, configuration: config)
    /// let element = try await checkout.getExpressCheckoutElement()
    /// ```
    ///
    /// - Returns: A ready-to-display ``ExpressCheckoutElement``.
    /// - Throws: An error if the element could not be loaded.
    public func getExpressCheckoutElement() async throws -> ExpressCheckoutElement {
        try await awaitPendingOperations()

        var eceConfiguration = configuration.expressCheckout
        eceConfiguration.apiClient = apiClient
        session.applyAddressOverrides(to: &eceConfiguration)

        AnalyticsHelper.shared.generateSessionID()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: ExpressCheckoutElement.self)
        let analyticsHelper = PaymentSheetAnalyticsHelper(
            integrationShape: .flowController,
            configuration: eceConfiguration
        )

        let (loadResult, _) = try await PaymentSheetLoader.load(
            mode: .checkout(self),
            configuration: eceConfiguration,
            analyticsHelper: analyticsHelper,
            integrationShape: .flowController
        )

        return ExpressCheckoutElement(
            checkout: self,
            configuration: eceConfiguration,
            loadResult: loadResult,
            analyticsHelper: analyticsHelper
        )
    }
}
