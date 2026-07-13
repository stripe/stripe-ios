//
//  PaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import SwiftUI
import UIKit

/// PaymentElement collects the customer's payment method, either in an embeddable view or presented in a sheet.
@MainActor
@_spi(STP)
public final class PaymentElement {
    // MARK: - Public Properties

    /// A SwiftUI View that displays payment methods.
    public internal(set) var view: PaymentElementView

    /// A UIView that displays payment methods.
    public internal(set) var uiView: PaymentElementUIView

    // MARK: - Public methods

    /// Presents a sheet that displays payment methods.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// Returns when the sheet is dismissed.
    public func present(from viewController: UIViewController? = nil) async {
        await withCheckedContinuation { continuation in
            present(from: viewController) {
                continuation.resume()
            }
        }
    }

    /// Presents a sheet that displays payment methods.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// - Parameter completion: Called when the sheet is dismissed.
    public func present(from viewController: UIViewController? = nil, completion: (() -> Void)? = nil) {
        guard let presentingViewController = viewController ?? UIWindow.visibleViewController else {
            let errorMessage = "PaymentElement.present(from:) could not find a presenting view controller."
            assertionFailure(errorMessage)
            let analytic = UnexpectedCheckoutElementsErrorAnalytic(
                errorCode: .paymentElementPresentingViewControllerUnavailable,
                errorMessage: errorMessage
            )
            STPAnalyticsClient.sharedClient.log(analytic: analytic)
            completion?()
            return
        }

        paymentSheetFlowController.presentPaymentOptions(from: presentingViewController) { _ in
            completion?()
        }
    }

    // MARK: - Internal Properties

    let paymentSheetFlowController: PaymentSheet.FlowController
    let embeddedPaymentElement: EmbeddedPaymentElement

    // MARK: - Internal methods

    init(checkout: Checkout) async throws {
        // Note: PaymentElement is just nice user-facing packaging around the existing Embedded and FC classes
        let paymentSheetConfiguration = checkout.configuration.paymentElement.makePaymentSheetConfiguration(
            apiClient: checkout.apiClient
        )
        self.paymentSheetFlowController = try await PaymentSheet.FlowController.create(
            checkout: checkout,
            configuration: paymentSheetConfiguration
        )
        let embeddedConfiguration = checkout.configuration.paymentElement.makeEmbeddedConfiguration(
            apiClient: checkout.apiClient
        )
        self.embeddedPaymentElement = try await EmbeddedPaymentElement.create(
            checkout: checkout,
            configuration: embeddedConfiguration
        )
        self.view = PaymentElementView()
        self.uiView = PaymentElementUIView()
    }
}

// MARK: - UIKit

/// A view that displays payment methods.
@_spi(STP)
public final class PaymentElementUIView: UIView {
    /// A delegate for the view.
    public weak var delegate: PaymentElementViewDelegate?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@MainActor
@_spi(STP)
public protocol PaymentElementViewDelegate: AnyObject {
    /// Called inside an animation block when the PaymentElement view is updating its height.
    func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView)

    /// Called immediately before the PaymentElement view presents.
    func paymentElementViewWillPresent(paymentElementView: PaymentElementUIView)
}

public extension PaymentElementViewDelegate {
    func paymentElementViewWillPresent(paymentElementView: PaymentElementUIView) {
        // Default implementation does nothing.
    }
}

// MARK: - SwiftUI

/// A view that displays payment methods.
@_spi(STP)
public struct PaymentElementView: View {
    public init() {}

    public var body: some View {
        EmptyView()
    }
}
