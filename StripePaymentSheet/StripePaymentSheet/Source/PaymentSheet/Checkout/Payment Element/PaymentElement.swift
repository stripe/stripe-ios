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
    /// Returns when the sheet is dismissed.
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

    init(
        checkout: CheckoutController,
        flowControllerInitParameters: CheckoutControllerLoader.FlowControllerInitializationParameters,
        embeddedPaymentElementInitParameters: CheckoutControllerLoader.EmbeddedPaymentElementInitializationParameters
    ) throws {
        try EmbeddedPaymentElement.validateRowSelectionConfiguration(
            configuration: embeddedPaymentElementInitParameters.configuration,
            customerProvider: embeddedPaymentElementInitParameters.loadResult.customerProvider
        )
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentSheet.FlowController.self)
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: EmbeddedPaymentElement.self)
        // Build FC
        self.paymentSheetFlowController = .init(
            configuration: flowControllerInitParameters.configuration,
            loadResult: flowControllerInitParameters.loadResult,
            analyticsHelper: flowControllerInitParameters.analyticsHelper
        )
        self.paymentSheetFlowController.checkout = checkout
        self.paymentSheetFlowController.viewController.checkoutBillingAddressUpdater = checkout
        // Reading paymentOption preloads its image into the cache before initialization completes.
        _ = self.paymentSheetFlowController.paymentOption

        // Build Embedded
        self.embeddedPaymentElement = .init(
            configuration: embeddedPaymentElementInitParameters.configuration,
            loadResult: embeddedPaymentElementInitParameters.loadResult,
            analyticsHelper: embeddedPaymentElementInitParameters.analyticsHelper,
            initialSelection: paymentSheetFlowController.internalPaymentOption.map(RowButtonType.init)
        )
        self.embeddedPaymentElement.checkout = checkout
        self.embeddedPaymentElement.notifiesDelegateOnInitialHeight = true
        let uiView = PaymentElementUIView(contentView: embeddedPaymentElement.view)
        self.view = PaymentElementView(viewModel: PaymentElementViewModel(uiView: uiView))
        self.uiView = uiView
        self.embeddedPaymentElement.delegate = self
        self.checkout = checkout

        // When FC paymentOption updates, update checkout's payment option too
        self.paymentSheetFlowController.$paymentOption
            // Without dropFirst, @Published immediately emits FlowController's current value before we setPaymentOption from EmbeddedPaymentElement below.
            .dropFirst()
            .sink { [weak self] paymentOption in
                guard let self, !isSuppressingPaymentOptionUpdates else {
                    return
                }
                paymentOptionSourceOfTruthIsFlowController = true
                self.checkout?.dangerouslySetPaymentOptionDirectly(paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init))
            }
            .store(in: &cancellables)

        // Set the default payment option
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
        checkout.dangerouslySetPaymentOptionDirectly(
            embeddedPaymentElement.paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init)
        )
        paymentOptionSourceOfTruthIsFlowController = false // We used embedded's payment option
    }
}

// MARK: - Checkout Updates

extension PaymentElement {
    var isPresentingPaymentUI: Bool {
        return paymentSheetFlowController.isPresentingPaymentUI || embeddedPaymentElement.isPresentingPaymentUI
    }

    func apply(
        flowControllerInitParameters: CheckoutControllerLoader.FlowControllerInitializationParameters,
        embeddedPaymentElementInitParameters: CheckoutControllerLoader.EmbeddedPaymentElementInitializationParameters,
        checkout: CheckoutController
    ) {
        // Suppress updating CheckoutController payment option while reloading FC and Embedded - we only want to update once, at the end.
        isSuppressingPaymentOptionUpdates = true
        defer { isSuppressingPaymentOptionUpdates = false }

        // Update FC and Embedded configurations (email/shipping could have changed)
        paymentSheetFlowController.configuration = flowControllerInitParameters.configuration
        embeddedPaymentElement.configuration = embeddedPaymentElementInitParameters.configuration

        // Update FC with new session
        paymentSheetFlowController.applyLoadResult(flowControllerInitParameters.loadResult, confirmationChallenge: nil)

        // Update Embedded with new session
        embeddedPaymentElement.applyLoadResult(
            embeddedPaymentElementInitParameters.loadResult,
            confirmationChallenge: nil,
            configuration: embeddedPaymentElementInitParameters.configuration
        )

        // Update checkout's payment option after both UIs have been updated
        updatePaymentOption(checkout: checkout)
    }

    func updatePaymentOption(checkout: CheckoutController) {
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
        checkout.dangerouslySetPaymentOptionDirectly(paymentOption)
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
        try await checkout.updateBillingTaxRegionIfNecessary(address: nil)
        checkout.dangerouslySetPaymentOptionDirectly(nil)
        embeddedPaymentElement.clearPaymentOption()
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
        checkout?.dangerouslySetPaymentOptionDirectly(embeddedPaymentElement.paymentOption.map(CheckoutController.Session.PaymentOptionDisplayData.init))
    }
}

// MARK: - CheckoutController.Session.PaymentOptionDisplayData

extension CheckoutController.Session.PaymentOptionDisplayData {
    init(_ paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData) {
        self.init(
            image: paymentOption.image,
            label: paymentOption.labels.label,
            sublabel: paymentOption.labels.sublabel,
            billingDetails: paymentOption.billingDetails.map(BillingDetails.init),
            paymentMethodType: paymentOption.paymentMethodType,
            mandateText: nil
        )
    }

    init(_ paymentOption: EmbeddedPaymentElement.PaymentOptionDisplayData) {
        self.init(
            image: paymentOption.image,
            label: paymentOption.labels.label,
            sublabel: paymentOption.labels.sublabel,
            billingDetails: paymentOption.billingDetails.map(BillingDetails.init),
            paymentMethodType: paymentOption.paymentMethodType,
            mandateText: paymentOption.mandateText
        )
    }
}

private extension CheckoutController.Session.PaymentOptionDisplayData.BillingDetails {
    init(_ billingDetails: PaymentSheet.BillingDetails) {
        self.init(
            address: billingDetails.address == .init() ? nil : Address(billingDetails.address),
            email: billingDetails.email,
            name: billingDetails.name,
            phone: billingDetails.phone
        )
    }
}

private extension CheckoutController.Session.PaymentOptionDisplayData.BillingDetails.Address {
    init(_ address: PaymentSheet.Address) {
        self.init(
            city: address.city,
            country: address.country,
            line1: address.line1,
            line2: address.line2,
            postalCode: address.postalCode,
            state: address.state
        )
    }
}
