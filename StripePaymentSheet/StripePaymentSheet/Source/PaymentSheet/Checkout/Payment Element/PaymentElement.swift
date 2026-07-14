//
//  PaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

import Combine
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
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
    weak var checkout: Checkout?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal methods

    init(checkout: Checkout) async throws {
        // Note: PaymentElement is just nice user-facing packaging around the existing Embedded and FC classes
        // Create FlowController
        let paymentSheetConfiguration = checkout.configuration.paymentElement.makePaymentSheetConfiguration(
            apiClient: checkout.apiClient
        )
        self.paymentSheetFlowController = try await PaymentSheet.FlowController.create(
            checkout: checkout,
            configuration: paymentSheetConfiguration
        )
        // Create Embedded
        let embeddedConfiguration = checkout.configuration.paymentElement.makeEmbeddedConfiguration(
            apiClient: checkout.apiClient
        )
        self.embeddedPaymentElement = try await EmbeddedPaymentElement.create(
            checkout: checkout,
            configuration: embeddedConfiguration
        )
        self.embeddedPaymentElement.notifiesDelegateOnInitialHeight = true
        let uiView = PaymentElementUIView(contentView: embeddedPaymentElement.view)
        self.view = PaymentElementView(viewModel: PaymentElementViewModel(uiView: uiView))
        self.uiView = uiView
        self.embeddedPaymentElement.delegate = self
        self.checkout = checkout
        self.paymentSheetFlowController.$paymentOption
            // Without dropFirst, @Published immediately emits FlowController's current value before we setPaymentOption from EmbeddedPaymentElement below.
            .dropFirst()
            .sink { [weak self] paymentOption in
                self?.checkout?.setPaymentOption(paymentOption.map(Checkout.Session.PaymentOptionDisplayData.init))
            }
            .store(in: &cancellables)
        // We don't know whether to use FC or Embedded's payment option at this point, so we'll use Embedded since it has more info (includes mandate text).
        checkout.setPaymentOption(
            embeddedPaymentElement.paymentOption.map(Checkout.Session.PaymentOptionDisplayData.init)
        )
    }
}

// MARK: - Checkout Updates

extension PaymentElement {
    var isPresentingPaymentUI: Bool {
        return paymentSheetFlowController.isPresentingPaymentUI || embeddedPaymentElement.isPresentingPaymentUI
    }

    func update(checkout: Checkout) async throws {
        // TODO: This should not be async or throws; we should not make any network requests or re-fetch things, just update the v1/e/s response.
        // Update FlowController
        try await paymentSheetFlowController.update(checkout: checkout)

        // Update Embedded
        let result = await embeddedPaymentElement.update(checkout: checkout)
        if case .failed(let error) = result {
            throw error
        }
    }

    func clearPaymentOption() {
        paymentSheetFlowController.clearPaymentOption()
        embeddedPaymentElement.clearPaymentOption()
        checkout?.setPaymentOption(nil)
    }
}

// MARK: - EmbeddedPaymentElementDelegate

// Note: The EPE delegate methods just get forwarded to the PaymentElementUIView delegate
extension PaymentElement: EmbeddedPaymentElementDelegate {
    public func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        uiView.embeddedPaymentElementDidUpdateHeight()
    }

    public func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement) {
        uiView.embeddedPaymentElementWillPresent()
    }

    public func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        checkout?.setPaymentOption(embeddedPaymentElement.paymentOption.map(Checkout.Session.PaymentOptionDisplayData.init))
    }
}

// MARK: - Checkout.Session.PaymentOptionDisplayData

extension Checkout.Session.PaymentOptionDisplayData {
    init(_ paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData) {
        self.init(
            image: paymentOption.image,
            label: paymentOption.label,
            billingDetails: paymentOption.billingDetails,
            paymentMethodType: paymentOption.paymentMethodType,
            mandateText: nil
        )
    }

    init(_ paymentOption: EmbeddedPaymentElement.PaymentOptionDisplayData) {
        self.init(
            image: paymentOption.image,
            label: paymentOption.label,
            billingDetails: paymentOption.billingDetails,
            paymentMethodType: paymentOption.paymentMethodType,
            mandateText: paymentOption.mandateText
        )
    }
}
