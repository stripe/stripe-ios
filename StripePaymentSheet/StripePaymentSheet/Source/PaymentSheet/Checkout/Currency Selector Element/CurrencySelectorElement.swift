//
//  CurrencySelectorElement.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 4/8/26.
//

@_spi(STP) import StripeCore

/// Handles Checkout mutations requested by a CurrencySelectorElement.
@MainActor
protocol CurrencySelectorElementCheckoutDelegate: AnyObject {
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

    /// See ``CurrencySelectorElementDelegate``.
    public weak var delegate: CurrencySelectorElementDelegate?

    /// A SwiftUI view that displays the currency selector.
    public let view: CurrencySelectorElementView

    /// A self-sizing UIKit view that displays the currency selector.
    ///
    /// Do not constrain the view to a fixed height. Use ``CurrencySelectorElementDelegate``
    /// to coordinate changes to the view's height with its surrounding layout.
    public let uiView: CurrencySelectorElementUIView

    // MARK: - Internal Methods

    init?(
        sessionSource: CheckoutSessionSource,
        configuration: Configuration,
        delegate: CurrencySelectorElementCheckoutDelegate
    ) async {
        guard let uiView = await CurrencySelectorElementUIView(
            session: sessionSource.initialSession,
            delegate: delegate,
            appearance: configuration.appearance
        ) else {
            return nil
        }
        let viewModel = CurrencySelectorElementViewModel(
            sessionSource: sessionSource,
            uiView: uiView,
        )

        self.uiView = uiView
        self.view = CurrencySelectorElementView(viewModel: viewModel)
        self.uiView.needsUpdateSuperviewHeight = { [weak self] in
            guard let self else { return }
            self.delegate?.currencySelectorElementDidUpdateHeight(currencySelectorElement: self)
        }
        STPAnalyticsClient.sharedClient.log(
            analytic: PaymentSheetAnalytic(
                event: .adaptivePricingCurrencySelectorInit,
                additionalParams: ["checkout_session_id": sessionSource.initialSession.id],
            )
        )
    }
}

@MainActor
@_spi(STP)
@_spi(ReactNativeSDK)
public protocol CurrencySelectorElementDelegate: AnyObject {
    /// Called inside an animation block when the CurrencySelectorElement view is updating its height. Your implementation should call `setNeedsLayout()` and `layoutIfNeeded` on the scroll view that contains the CurrencySelectorElement view. This enables a smooth animation of the height change.
    func currencySelectorElementDidUpdateHeight(currencySelectorElement: CurrencySelectorElement)
}
