//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(STP) import StripeCore

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

    // MARK: - Init

    init(
        sessionSource: CheckoutSessionSource,
        configuration: Checkout.Configuration,
        delegate: ExpressCheckoutElementDelegate
    ) {
        let paymentMethods = ExpressCheckoutElement.availablePaymentMethods(
            for: sessionSource.initialSession,
            configuration: configuration
        )
        let uiView = ExpressCheckoutElementUIView(
            paymentMethods: paymentMethods,
            session: sessionSource.initialSession,
            configuration: configuration,
            delegate: delegate
        )
        let viewModel = ExpressCheckoutElementViewModel(
            sessionSource: sessionSource,
            configuration: configuration,
            uiView: uiView
        )
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
    }

    // MARK: - Payment Method Resolution

    static func availablePaymentMethods(
        for session: Checkout.Session,
        configuration: Checkout.Configuration
    ) -> [PaymentMethod] {
        let eceConfig = configuration.expressCheckoutElement

        var buttons: [PaymentMethod] = []

        for button in session.availableExpressCheckoutPaymentMethods {
            switch button {
            case .applePay:
                if eceConfig.paymentMethods.applePay != .never,
                    configuration.applePayConfiguration != nil,
                    StripeAPI.deviceSupportsApplePay() {
                    buttons.append(.applePay)
                }
            case .link:
                if eceConfig.paymentMethods.link != .never && configuration.linkConfiguration?.display != .never {
                    buttons.append(.link)
                }
            }
        }

        // .always: include even if the session does not advertise the wallet
        if eceConfig.paymentMethods.applePay == .always,
            configuration.applePayConfiguration != nil,
            StripeAPI.deviceSupportsApplePay(),
            !buttons.contains(.applePay) {
            buttons.append(.applePay)
        }
        if eceConfig.paymentMethods.link == .always, !buttons.contains(.link) {
            buttons.append(.link)
        }

        return buttons
    }
}
