//
//  CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/8/26.
//

@_spi(STP) import StripeCore

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

    // MARK: - Private Properties

    private let viewModel: CurrencySelectorElementViewModel

    // MARK: - Internal Methods

    init(checkout: Checkout) async {
        let flagImageManager = AdaptivePricingFlagImageManager()
        await flagImageManager.prefetchFlagImages(for: checkout.session)

        let uiView = CurrencySelectorElementUIView(
            checkout: checkout,
            appearance: checkout.configuration.currencySelectorElement.appearance,
            flagImageManager: flagImageManager
        )
        let viewModel = CurrencySelectorElementViewModel(
            checkout: checkout,
            uiView: uiView,
        )

        self.uiView = uiView
        self.viewModel = viewModel
        self.view = CurrencySelectorElementView(viewModel: viewModel)
        STPAnalyticsClient.sharedClient.log(
            analytic: PaymentSheetAnalytic(
                event: .adaptivePricingCurrencySelectorInit,
                additionalParams: [:],
            )
        )
    }
}
