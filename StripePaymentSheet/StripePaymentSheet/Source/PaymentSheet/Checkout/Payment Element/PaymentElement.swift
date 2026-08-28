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
    weak var checkout: CheckoutController?
    private var cancellables = Set<AnyCancellable>()
    var paymentOptionSourceOfTruthIsFlowController = false
    private var isSuppressingPaymentOptionUpdates = false

    // MARK: - Internal methods

    init(checkout: CheckoutController) async throws {
        // Note: PaymentElement is just nice user-facing packaging around the existing Embedded and FC classes
        let configuration = checkout.configuration.paymentElement

        // Create FlowController
        let paymentSheetConfiguration = configuration.makePaymentSheetConfiguration(
            apiClient: checkout.apiClient,
            returnURL: checkout.configuration.returnURL,
            defaults: checkout.configuration.defaults,
            merchantDisplayName: checkout.effectiveMerchantDisplayName,
            merchantCountryCode: checkout.session.merchantCountryCode,
            userInterfaceStyle: checkout.configuration.userInterfaceStyle
        )
        self.paymentSheetFlowController = try await PaymentSheet.FlowController.create(
            checkout: checkout,
            configuration: paymentSheetConfiguration
        )
        // Create Embedded
        let embeddedConfiguration = configuration.makeEmbeddedConfiguration(
            apiClient: checkout.apiClient,
            returnURL: checkout.configuration.returnURL,
            defaults: checkout.configuration.defaults,
            merchantDisplayName: checkout.effectiveMerchantDisplayName,
            merchantCountryCode: checkout.session.merchantCountryCode,
            userInterfaceStyle: checkout.configuration.userInterfaceStyle
        )
        self.embeddedPaymentElement = try await EmbeddedPaymentElement.create(
            checkout: checkout,
            configuration: embeddedConfiguration,
            // FlowController and Embedded naturally have different default payment options (e.g. Apple Pay and Link).
            // Keep them in sync by seeding Embedded's initial payment option with FlowController's.
            initialPaymentOption: paymentSheetFlowController.internalPaymentOption
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
                guard let self, !isSuppressingPaymentOptionUpdates else {
                    return
                }
                paymentOptionSourceOfTruthIsFlowController = true
                self.checkout?.setPaymentOption(paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init))
            }
            .store(in: &cancellables)
        // We don't know whether to use FC or Embedded's payment option at this point, so we'll use Embedded since it has more info (includes mandate text).
        // FlowController defaults to Apple Pay when it is available, while Embedded starts unselected.
        let flowControllerDefaultsToApplePay = if case .applePay? = paymentSheetFlowController.internalPaymentOption {
            embeddedPaymentElement._paymentOption == nil
        } else {
            false
        }
        stpAssert(
            paymentSheetFlowController.paymentOption?.label == embeddedPaymentElement.paymentOption?.label || flowControllerDefaultsToApplePay,
            "Payment Element assumes that the FlowController's payment option is the same as the Embedded's on first load!"
        )
        checkout.setPaymentOption(
            embeddedPaymentElement.paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init)
        )
        paymentOptionSourceOfTruthIsFlowController = false // We used embedded's payment option
        try await checkout.syncBillingAddress(from: embeddedPaymentElement._paymentOption?.checkoutBillingDetails)
    }
}

// MARK: - Checkout Updates

extension PaymentElement {
    var isPresentingPaymentUI: Bool {
        return paymentSheetFlowController.isPresentingPaymentUI || embeddedPaymentElement.isPresentingPaymentUI
    }

    func update(checkout: CheckoutController) async throws {
        // FlowController.update and EmbeddedPaymentElement.update can both publish their current/default payment option while applying the new Checkout session. Suppress those intermediate callbacks - we'll explicitly set the payment option ourselves in this method.
        stpAssert(!isSuppressingPaymentOptionUpdates, "PaymentElement.update(checkout:) does not support overlapping updates.")
        isSuppressingPaymentOptionUpdates = true
        defer {
            isSuppressingPaymentOptionUpdates = false
        }

        // TODO: This should not be async or throws; we should not make any network requests or re-fetch things, just update the v1/e/s response.
        let configuration = checkout.configuration.paymentElement
        paymentSheetFlowController.configuration = configuration.makePaymentSheetConfiguration(
            apiClient: checkout.apiClient,
            returnURL: checkout.configuration.returnURL,
            defaults: checkout.configuration.defaults,
            merchantDisplayName: checkout.effectiveMerchantDisplayName,
            merchantCountryCode: checkout.session.merchantCountryCode,
            userInterfaceStyle: checkout.configuration.userInterfaceStyle
        )
        embeddedPaymentElement.configuration = configuration.makeEmbeddedConfiguration(
            apiClient: checkout.apiClient,
            returnURL: checkout.configuration.returnURL,
            defaults: checkout.configuration.defaults,
            merchantDisplayName: checkout.effectiveMerchantDisplayName,
            merchantCountryCode: checkout.session.merchantCountryCode,
            userInterfaceStyle: checkout.configuration.userInterfaceStyle
        )

        // Update FlowController
        try await paymentSheetFlowController.update(checkout: checkout)

        // Update Embedded
        let result = await embeddedPaymentElement.update(checkout: checkout)
        if case .failed(let error) = result {
            throw error
        }

        // Update payment option
        // Problem: Since (unfortunately) we have two sources of truth for payment option (FC and Embedded), we need to know which one to pick. We can't just let them both update payment option - then the last one to update will win, even when it wasn't actually used by the customer.
        // Hacky solution: We determine which one to pick based on which one last reported a payment option update.
        // If neither was used, their payment options should be equal (the default), and we pick one arbitrarily.
        let paymentOption = {
            if paymentOptionSourceOfTruthIsFlowController {
                paymentSheetFlowController.paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init)
            } else {
                embeddedPaymentElement.paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init)
            }
        }()
        checkout.setPaymentOption(paymentOption)
    }

    func clearPaymentOption() async throws {
        guard !paymentSheetFlowController.didPresentAndContinue else {
            assertionFailure("Clearing the payment option after presenting PaymentElement is not implemented. File a feature request if you need this.")
            return
        }
        guard let checkout else {
            stpAssertionFailure("PaymentElement unexpectedly lost its CheckoutController.")
            return
        }
        try await checkout.enqueueSessionUpdate {
            if checkout.session.collectsTaxFromBillingAddress,
               let country = checkout.session.paymentOption?.billingDetails?.address.country?.nonEmpty {
                // The update endpoint requires a country, so clear the rest of the tax region
                // while retaining the selected payment option's country.
                try await checkout.applySessionUpdate(
                    .setTaxRegion(CheckoutController.Address(country: country))
                )
            }
            self.embeddedPaymentElement.clearPaymentOption()
            checkout.setPaymentOption(nil)
        }
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
        guard !isSuppressingPaymentOptionUpdates else {
            return
        }
        paymentOptionSourceOfTruthIsFlowController = false
        checkout?.setPaymentOption(embeddedPaymentElement.paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init))
    }
}

// MARK: - CheckoutController.Session.PaymentOptionDisplayData

extension CheckoutController.Session.PaymentOptionDisplayData {
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
