//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import UIKit

/// Handles Checkout interactions initiated by an ``ExpressCheckoutElementUIView``.
@MainActor
protocol ExpressCheckoutElementDelegate: AnyObject {
    /// Called when the customer taps the Apple Pay button.
    ///
    /// The delegate is responsible for confirming the Checkout Session via Apple Pay and
    /// must call `completion` with the result when the Apple Pay sheet is dismissed.
    ///
    /// - Parameters:
    ///   - element: The view that received the tap.
    ///   - window: The window to present the Apple Pay sheet from, if available.
    ///   - completion: Called with the confirmation result.
    func expressCheckoutElementDidTapApplePay(
        _ element: ExpressCheckoutElementUIView,
        window: UIWindow?,
        completion: @escaping (Checkout.ConfirmResult) -> Void
    )
}

/// An express checkout element backed by a Checkout Session.
///
/// Obtain an instance from ``Checkout/getExpressCheckoutElement()`` and use
/// ``view`` in SwiftUI or ``uiView`` in UIKit.
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElement {

    // MARK: - Public Properties

    /// A SwiftUI view that displays the express checkout buttons.
    public let view: ExpressCheckoutElementView

    /// A UIKit view that displays the express checkout buttons.
    public let uiView: ExpressCheckoutElementUIView

    // MARK: - Init

    init(
        sessionSource: CheckoutSessionSource,
        configuration: Checkout.Configuration,
        delegate: ExpressCheckoutElementDelegate
    ) {
        let uiView = ExpressCheckoutElementUIView(session: sessionSource.initialSession, configuration: configuration, delegate: delegate)
        let viewModel = ExpressCheckoutElementViewModel(sessionSource: sessionSource, configuration: configuration, uiView: uiView)
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
    }
}
