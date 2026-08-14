//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

/// Handles Checkout mutations requested by an ExpressCheckoutElement.
@MainActor
protocol ExpressCheckoutElementDelegate: AnyObject {
    // TODO: Add delegate methods for Apple Pay and Link button taps
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

    /// The wallet payment methods currently available to show, given the session and configuration.
    public var availableExpressCheckoutPaymentMethods: [ExpressCheckoutElement.ExpressButton] {
        viewModel.availableExpressCheckoutPaymentMethods
    }

    weak var delegate: ExpressCheckoutElementDelegate? {
        didSet { uiView.delegate = delegate }
    }

    // MARK: - Private Properties

    private let viewModel: ExpressCheckoutElementViewModel

    // MARK: - Init

    /// Buttons aren't populated until ``attach(sessionSource:)`` is called, since the initial
    /// session isn't known until Checkout finishes initializing.
    init(configuration: Checkout.Configuration) {
        let uiView = ExpressCheckoutElementUIView(configuration: configuration)
        let viewModel = ExpressCheckoutElementViewModel(configuration: configuration, uiView: uiView)
        self.uiView = uiView
        self.viewModel = viewModel
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
    }

    // MARK: - Internal Methods

    func attach(sessionSource: CheckoutSessionSource) {
        viewModel.attach(sessionSource: sessionSource)
    }
}
