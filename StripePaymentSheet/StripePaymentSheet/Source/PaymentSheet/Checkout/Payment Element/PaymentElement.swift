//
//  PaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

import Combine
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

/// PaymentElement collects the customer's payment method, either in an embeddable view or presented in a sheet.
@MainActor
@_spi(ReactNativeSDK)
@_spi(CheckoutSessionPreview)
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

        paymentSheetFlowController.presentPaymentOptions(from: presentingViewController) { [weak self] didCancel in
            // The customer continued from FlowController's sheet, so its selection is now Checkout's payment option.
            if !didCancel, let self, let checkout {
                paymentOptionSourceOfTruthIsFlowController = true
                updatePaymentOption(checkout: checkout)
            }
            completion?()
        }
    }

    // MARK: - Internal Properties

    let paymentSheetFlowController: PaymentSheet.FlowController
    let embeddedPaymentElement: EmbeddedPaymentElement
    weak var checkout: CheckoutElementsController?
    private var cancellables = Set<AnyCancellable>()
    var paymentOptionSourceOfTruthIsFlowController = false
    private var isSuppressingPaymentOptionUpdates = false

    // MARK: - Internal methods

    init(
        checkout: CheckoutElementsController,
        flowControllerInitParameters: CheckoutElementsControllerLoader.FlowControllerInitializationParameters,
        embeddedPaymentElementInitParameters: CheckoutElementsControllerLoader.EmbeddedPaymentElementInitializationParameters
    ) throws {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: PaymentElement.self)
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
        let uiView = PaymentElementUIView(
            contentView: embeddedPaymentElement.view,
            userInterfaceStyle: embeddedPaymentElementInitParameters.configuration.style
        )
        self.view = PaymentElementView(viewModel: PaymentElementViewModel(uiView: uiView))
        self.uiView = uiView
        self.embeddedPaymentElement.delegate = self
        self.checkout = checkout

        // When FC paymentOption updates, update checkout's payment option too - but only once the customer has used FC's sheet.
        // FC republishes its untouched selection on its own (e.g. when the Link account changes), which must not replace the customer's Embedded selection.
        self.paymentSheetFlowController.$paymentOption
            // Without dropFirst, @Published immediately emits FlowController's current value before we setPaymentOption from EmbeddedPaymentElement below.
            .dropFirst()
            .sink { [weak self] paymentOption in
                guard let self, !isSuppressingPaymentOptionUpdates, paymentOptionSourceOfTruthIsFlowController else {
                    return
                }
                self.checkout?.dangerouslySetPaymentOptionDirectly(paymentOption.map(CheckoutElementsController.Session.PaymentOptionDisplayData.init))
                self.syncShippingAddressFromLink(self.paymentSheetFlowController.internalPaymentOption)
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
            embeddedPaymentElement.paymentOption.map(CheckoutElementsController.Session.PaymentOptionDisplayData.init)
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
        flowControllerInitParameters: CheckoutElementsControllerLoader.FlowControllerInitializationParameters,
        embeddedPaymentElementInitParameters: CheckoutElementsControllerLoader.EmbeddedPaymentElementInitializationParameters,
        checkout: CheckoutElementsController
    ) {
        // Suppress updating CheckoutElementsController payment option while reloading FC and Embedded - we only want to update once, at the end.
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

    func updatePaymentOption(checkout: CheckoutElementsController) {
        // Update payment option
        // Problem: Since (unfortunately) we have two sources of truth for payment option (FC and Embedded), we need to know which one to pick. We can't just let them both update payment option - then the last one to update will win, even when it wasn't actually used by the customer.
        // Hacky solution: We pick FlowController once the customer continues from its sheet, and Embedded once they select a payment option in it.
        // If neither was used, their payment options should be equal (the default), and we pick one arbitrarily.
        let paymentOption = {
            if paymentOptionSourceOfTruthIsFlowController {
                paymentSheetFlowController.paymentOption.map(CheckoutElementsController.Session.PaymentOptionDisplayData.init)
            } else {
                embeddedPaymentElement.paymentOption.map(CheckoutElementsController.Session.PaymentOptionDisplayData.init)
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
            stpAssertionFailure("PaymentElement unexpectedly lost its CheckoutElementsController.")
            return
        }
        try await checkout.updateBillingTaxRegionIfNecessary(address: nil, source: .paymentElement)
        checkout.dangerouslySetPaymentOptionDirectly(nil)
        embeddedPaymentElement.clearPaymentOption()
    }
}

// MARK: - EmbeddedPaymentElementDelegate

// Note: The EPE delegate methods just get forwarded to the PaymentElementUIView delegate
@_spi(InternalOnlyAPI) extension PaymentElement: EmbeddedPaymentElementDelegate {
    @_spi(InternalOnlyAPI) public func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        uiView.embeddedPaymentElementDidUpdateHeight()
    }

    @_spi(InternalOnlyAPI) public func embeddedPaymentElementWillPresent(embeddedPaymentElement: EmbeddedPaymentElement) {
        uiView.embeddedPaymentElementWillPresent()
    }

    @_spi(InternalOnlyAPI) public func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        guard !isSuppressingPaymentOptionUpdates else {
            return
        }
        paymentOptionSourceOfTruthIsFlowController = false
        checkout?.dangerouslySetPaymentOptionDirectly(embeddedPaymentElement.paymentOption.map(CheckoutElementsController.Session.PaymentOptionDisplayData.init))
        syncShippingAddressFromLink(embeddedPaymentElement._paymentOption)
    }
}

// MARK: - Link shipping address

extension PaymentElement {
    /// Sets the session's shipping address to the one the customer selected in native Link, if the session collects one,
    /// so the integration and Shipping Address Element show it.
    func syncShippingAddressFromLink(_ paymentOption: PaymentOption?) {
        guard let checkout,
              checkout.session.requiresShippingAddress,
              case .link(let confirmOption)? = paymentOption,
              let shippingAddress = confirmOption.checkoutShippingAddress,
              // e.g. the customer kept the session's shipping address
              shippingAddress != checkout.session.shippingAddress else {
            return
        }
        Task { @MainActor in
            // Best effort: if this fails, the customer can still enter a shipping address in the integration.
            try? await checkout.updateShippingAddress(
                name: shippingAddress.name,
                address: shippingAddress.address,
                source: .paymentElement,
                canUpdateWhileSheetPresented: true
            )
        }
    }
}

// MARK: - CheckoutElementsController.Session.PaymentOptionDisplayData

extension CheckoutElementsController.Session.PaymentOptionDisplayData {
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

private extension CheckoutElementsController.Session.PaymentOptionDisplayData.BillingDetails {
    init(_ billingDetails: PaymentSheet.BillingDetails) {
        self.init(
            address: billingDetails.address == .init() ? nil : Address(billingDetails.address),
            email: billingDetails.email,
            name: billingDetails.name,
            phone: billingDetails.phone
        )
    }
}

private extension CheckoutElementsController.Session.PaymentOptionDisplayData.BillingDetails.Address {
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

// MARK: - STPAnalyticsProtocol
/// :nodoc:
@_spi(InternalOnlyAPI) extension PaymentElement: STPAnalyticsProtocol {
    @_spi(InternalOnlyAPI) public nonisolated static let stp_analyticsIdentifier: String = "PaymentElement"
}
