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
    /// - Parameter presentingViewController: The view controller that owns the tapped button's window, used to present any UI required to confirm (e.g. Link authentication). This may differ from the view controller used elsewhere, e.g. with ``Checkout/confirm(from:)``.
    func expressCheckoutElementShouldConfirm(_ paymentMethod: ExpressCheckoutElement.PaymentMethod, presentingViewController: UIViewController?) async -> Checkout.ConfirmResult
}

/// An express checkout element backed by a Checkout Session.
///
/// Obtain an instance from ``Checkout/getExpressCheckoutElement(_:)`` and use
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
    public var availableExpressCheckoutPaymentMethods: [ExpressCheckoutElement.PaymentMethod] {
        viewModel.availableExpressCheckoutPaymentMethods
    }

    weak var delegate: ExpressCheckoutElementDelegate? {
        didSet { uiView.delegate = delegate }
    }

    private(set) var confirmHandler: ConfirmHandler? {
        didSet { uiView.confirmHandler = confirmHandler }
    }

    // MARK: - Private Properties

    private let viewModel: ExpressCheckoutElementViewModel

    // MARK: - Init

    /// Buttons aren't populated until ``attach(sessionSource:)`` is called, since the initial
    /// session isn't known until Checkout finishes initializing.
    init(configuration: ExpressCheckoutElement.Configuration) {
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

    func setConfirmHandler(_ confirmHandler: @escaping ConfirmHandler) {
        self.confirmHandler = confirmHandler
    }
}
