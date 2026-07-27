//
//  CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/8/26.
//

@_spi(STP) import StripeCore

/// Handles Checkout mutations requested by a CurrencySelectorElement.
@MainActor
protocol CurrencySelectorElementDelegate: AnyObject {
    /// Selects the currency identified by its three-letter ISO currency code.
    func selectCurrency(_ currency: String) async throws
}

/// An Adaptive Pricing currency selector backed by a Checkout Session.
///
/// Obtain an instance from ``Checkout/getCurrencySelectorElement()`` and use
/// ``view`` in SwiftUI or ``uiView`` in UIKit.
@MainActor
@_spi(STP)
@_spi(ReactNativeSDK)
public final class CurrencySelectorElement {
    // MARK: - Public Properties

    /// A SwiftUI view that displays the currency selector.
    public let view: CurrencySelectorElementView

    /// A UIKit view that displays the currency selector.
    public let uiView: CurrencySelectorElementUIView

    // MARK: - Internal Methods

    init(
        sessionSource: CheckoutSessionSource,
        configuration: Configuration,
        delegate: CurrencySelectorElementDelegate
    ) async {
        let uiView = await CurrencySelectorElementUIView(
            session: sessionSource.initialSession,
            delegate: delegate,
            appearance: configuration.appearance
        )
        let viewModel = CurrencySelectorElementViewModel(
            sessionSource: sessionSource,
            uiView: uiView,
        )

        self.uiView = uiView
        self.view = CurrencySelectorElementView(viewModel: viewModel)
        STPAnalyticsClient.sharedClient.log(
            analytic: PaymentSheetAnalytic(
                event: .adaptivePricingCurrencySelectorInit,
                additionalParams: [:],
            )
        )
    }
}
