//
//  ExpressCheckoutElement.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/// Handles Checkout mutations requested by an ExpressCheckoutElement.
@MainActor
protocol ExpressCheckoutElementCheckoutDelegate: AnyObject {
    func expressCheckoutElementShouldConfirm(
        _ paymentMethod: ExpressCheckoutElement.PaymentMethod,
        presentationWindow: UIWindow?
    ) async -> CheckoutElementsController.ConfirmResult
}

/// An express checkout element backed by a Checkout Session.
///
/// Obtain an instance from ``CheckoutElementsController/getExpressCheckoutElement()`` and use
/// ``view`` in SwiftUI or ``uiView`` in UIKit.
@_spi(InternalOnlyAPI)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElement {

    // MARK: - Public Properties

    /// See ``ExpressCheckoutElementDelegate``.
    public weak var delegate: ExpressCheckoutElementDelegate?

    /// A SwiftUI view that displays the express checkout buttons.
    public let view: ExpressCheckoutElementView

    /// A UIKit view that displays the express checkout buttons.
    public let uiView: ExpressCheckoutElementUIView

    // MARK: - Init

    init(
        sessionSource: CheckoutSessionSource,
        configuration: ExpressCheckoutElement.Configuration,
        userInterfaceStyle: CheckoutElementsController.UserInterfaceStyle,
        delegate: ExpressCheckoutElementCheckoutDelegate,
        apiClient: STPAPIClient
    ) {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: ExpressCheckoutElement.self)
        // Assign the callback's weak reference after the views finish initializing.
        weak var element: ExpressCheckoutElement?
        let uiView = ExpressCheckoutElementUIView(
            session: sessionSource.initialSession,
            configuration: configuration,
            userInterfaceStyle: userInterfaceStyle,
            delegate: delegate,
            apiClient: apiClient,
            needsUpdateSuperviewHeight: {
                guard let element else { return }
                element.delegate?.expressCheckoutElementDidUpdateHeight(expressCheckoutElement: element)
            }
        )
        let viewModel = ExpressCheckoutElementViewModel(sessionSource: sessionSource, uiView: uiView)
        self.uiView = uiView
        self.view = ExpressCheckoutElementView(viewModel: viewModel)
        element = self
    }
}

@MainActor
@_spi(InternalOnlyAPI)
@_spi(ReactNativeSDK)
public protocol ExpressCheckoutElementDelegate: AnyObject {
    /// Called when the ExpressCheckoutElement view is updating its height, e.g. because the set of displayed buttons changed. Your implementation should call `setNeedsLayout()` and `layoutIfNeeded` on the scroll view that contains the ExpressCheckoutElement view to animate the height change.
    func expressCheckoutElementDidUpdateHeight(expressCheckoutElement: ExpressCheckoutElement)
}

// MARK: - STPAnalyticsProtocol
/// :nodoc:
@_spi(InternalOnlyAPI) extension ExpressCheckoutElement: STPAnalyticsProtocol {
    @_spi(InternalOnlyAPI) public nonisolated static let stp_analyticsIdentifier: String = "ExpressCheckoutElement"
}
