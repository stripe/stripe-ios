//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

/// Handles Checkout mutations requested by an ExpressCheckoutElement.
@MainActor
protocol ExpressCheckoutElementDelegate: AnyObject {}

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
    public internal(set) var view: ExpressCheckoutElementView

    /// A UIKit view that displays the express checkout buttons.
    public internal(set) var uiView: ExpressCheckoutElementUIView

    // MARK: - Internal Properties

    private weak var delegate: ExpressCheckoutElementDelegate?

    // MARK: - Init

    init(
        sessionPublisher: Published<Checkout.Session>.Publisher,
        configuration: Checkout.Configuration,
        delegate: ExpressCheckoutElementDelegate
    ) {
        self.delegate = delegate
        let uiView = ExpressCheckoutElementUIView(configuration: configuration)
        let viewModel = ExpressCheckoutElementViewModel(sessionPublisher: sessionPublisher, uiView: uiView)
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
    }
}
