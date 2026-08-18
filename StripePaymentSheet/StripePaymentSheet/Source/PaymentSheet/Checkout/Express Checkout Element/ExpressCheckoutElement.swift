//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import UIKit

/// Handles Checkout mutations requested by an ExpressCheckoutElement.
@MainActor
protocol ExpressCheckoutElementDelegate: AnyObject {
    func expressCheckoutElementShouldConfirm(
        _ paymentMethod: ExpressCheckoutElement.PaymentMethod,
        presentingViewController: UIViewController
    ) async -> Checkout.ConfirmResult
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
        configuration: CheckoutController.Configuration,
        delegate: ExpressCheckoutElementDelegate
    ) {
        let uiView = ExpressCheckoutElementUIView(session: sessionSource.initialSession, configuration: configuration, delegate: delegate)
        let viewModel = ExpressCheckoutElementViewModel(sessionSource: sessionSource, configuration: configuration, uiView: uiView)
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
    }
}
