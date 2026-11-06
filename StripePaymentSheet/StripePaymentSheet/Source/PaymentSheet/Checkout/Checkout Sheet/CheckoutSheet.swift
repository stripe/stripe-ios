import Combine
@_spi(STP) import StripeCore
import SwiftUI
import UIKit

/// A complete, native checkout backed by a Checkout Session.
///
/// Create a sheet with your server's Checkout Session client secret, then call
/// `present(from:)`. The sheet collects contact, shipping, and payment details,
/// displays session pricing, and confirms the session through CheckoutController.
@available(iOS 16.0, *)
@_spi(STP)
@MainActor
public final class CheckoutSheet: ObservableObject {
    public struct Configuration {
        public var clientSecret: String
        public var returnURL: String
        public var apiClient: STPAPIClient = .shared
        public var merchantDisplayName: String?
        public var merchantLogo: UIImage?
        public var defaults = CheckoutController.Configuration.Defaults()
        public var applePay: PaymentElement.ApplePayConfiguration?
        public var allowsLink = true
        public var allowsAdaptivePricing = true
        public var userInterfaceStyle: PaymentSheet.UserInterfaceStyle = .automatic
        public var appearance: PaymentSheet.Appearance = CheckoutSheet.defaultAppearance

        /// Creates configuration for a modeless Checkout Session.
        public init(clientSecret: String, returnURL: String) {
            self.clientSecret = clientSecret
            self.returnURL = returnURL
        }
    }

    /// The current session, including the selected payment method and updated amounts.
    @Published public private(set) var session: CheckoutController.Session

    let model: CheckoutSheetModel
    private var navigationController: UINavigationController?
    private var completion: ((CheckoutController.ConfirmResult) -> Void)?
    private var sessionSubscription: AnyCancellable?

    public init(configuration: Configuration) async throws {
        let resultRelay = CheckoutSheetResultRelay()
        let checkoutConfiguration = Self.makeCheckoutConfiguration(configuration) { result in
            resultRelay.handleResult?(result)
        }
        let checkout = try await CheckoutController(configuration: checkoutConfiguration)
        session = checkout.session
        model = await CheckoutSheetModel(checkout: checkout, configuration: configuration)
        sessionSubscription = checkout.$session.sink { [weak self] session in self?.session = session }
        resultRelay.handleResult = { [weak model] result in model?.handleConfirmationResult(result) }
        model.onFinish = { [weak self] result in self?.finish(result) }
    }

    /// Presents Checkout Sheet. Returns after the customer closes the sheet or its confirmation.
    /// Payment failures and canceled authentication remain in the sheet so the customer can retry.
    public func present(from presentingViewController: UIViewController? = nil) async
        -> CheckoutController.ConfirmResult
    {
        await withCheckedContinuation { continuation in
            present(from: presentingViewController) { result in continuation.resume(returning: result) }
        }
    }

    public func present(
        from presentingViewController: UIViewController? = nil,
        completion: @escaping (CheckoutController.ConfirmResult) -> Void
    ) {
        guard navigationController == nil else {
            completion(
                .failed(
                    PaymentSheetError.integrationError(nonPIIDebugDescription: "Checkout Sheet is already presented.")
                )
            )
            return
        }
        guard let presenter = presentingViewController ?? UIWindow.visibleViewController,
            presenter.presentedViewController == nil
        else {
            completion(
                .failed(
                    PaymentSheetError.integrationError(
                        nonPIIDebugDescription: "Checkout Sheet requires an available presenting view controller."
                    )
                )
            )
            return
        }
        guard session.status == .open else {
            completion(
                .failed(
                    PaymentSheetError.integrationError(
                        nonPIIDebugDescription: "Checkout Sheet requires an open Checkout Session."
                    )
                )
            )
            return
        }
        self.completion = completion
        // Keep callback integrations alive until the presented checkout returns a result.
        model.onFinish = { [self] result in finish(result) }
        model.resetPresentation()
        let root = UIHostingController(rootView: CheckoutSheetRootView(model: model))
        root.view.backgroundColor = model.configuration.appearance.colors.background
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.modalPresentationStyle = .pageSheet
        model.configuration.userInterfaceStyle.configure(navigationController)
        navigationController.view.backgroundColor = model.configuration.appearance.colors.background
        model.navigationController = navigationController
        model.configureNavigationItem(root)
        navigationController.delegate = model
        if let sheet = navigationController.sheetPresentationController {
            model.updateCompactDetent()
            sheet.selectedDetentIdentifier = CheckoutSheetModel.compactDetentIdentifier
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 52
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.delegate = model
        }
        self.navigationController = navigationController
        model.checkout.getPaymentElement().embeddedPaymentElement.paymentUIHost = model
        presenter.present(navigationController, animated: true)
    }

    /// Refreshes the sheet after your server updates the Checkout Session.
    public func runServerUpdate(_ update: @escaping () async throws -> Void) async throws {
        try await model.checkout.runServerUpdate(update)
    }

    private func finish(_ result: CheckoutController.ConfirmResult) {
        guard let navigationController, let completion = self.completion else { return }
        self.completion = nil
        let complete = { [self] in
            model.checkout.getPaymentElement().embeddedPaymentElement.paymentUIHost = nil
            model.navigationController = nil
            model.onFinish = nil
            self.navigationController = nil
            completion(result)
        }
        if navigationController.presentingViewController == nil {
            complete()
        } else {
            navigationController.dismiss(animated: true, completion: complete)
        }
    }

    static func makeCheckoutConfiguration(
        _ configuration: Configuration,
        confirmHandler: @escaping ExpressCheckoutElement.ConfirmHandler
    ) -> CheckoutController.Configuration {
        var checkout = CheckoutController.Configuration(
            clientSecret: configuration.clientSecret,
            returnURL: configuration.returnURL
        )
        checkout.apiClient = configuration.apiClient
        checkout.merchantDisplayName = configuration.merchantDisplayName
        checkout.defaults = configuration.defaults
        checkout.userInterfaceStyle = configuration.userInterfaceStyle
        var payment = PaymentElement.Configuration()
        payment.appearance = configuration.appearance
        payment.applePayConfiguration = configuration.applePay
        payment.linkConfiguration = .init(display: configuration.allowsLink ? .automatic : .never)
        payment.displaysMandateText = false
        checkout.paymentElement = payment
        checkout.shippingAddressElement = .init()
        if configuration.allowsAdaptivePricing {
            var currency = CurrencySelectorElement.Configuration()
            currency.appearance.text = configuration.appearance.colors.text
            currency.appearance.selectedText = configuration.appearance.colors.text
            currency.appearance.textSecondary = configuration.appearance.colors.textSecondary
            currency.appearance.selectedBackground = configuration.appearance.colors.componentBackground
            currency.appearance.font = configuration.appearance.font.base
            currency.appearance.sizeScaleFactor = configuration.appearance.font.sizeScaleFactor
            checkout.currencySelectorElement = currency
        }
        var express = ExpressCheckoutElement.Configuration(confirmHandler: confirmHandler)
        express.collectsShippingAddressIfRequired = true
        express.buttonHeight = 55
        express.buttonCornerRadius = 28
        if let applePay = configuration.applePay {
            express.applePayConfiguration = .init(merchantId: applePay.merchantId)
        }
        express.linkConfiguration.display = configuration.allowsLink ? .automatic : .never
        checkout.expressCheckoutElement = express
        return checkout
    }

    nonisolated public static var defaultAppearance: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()
        appearance.colors.background = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
                : UIColor(white: 242 / 255, alpha: 1)
        }
        appearance.colors.componentBackground = .secondarySystemGroupedBackground
        appearance.colors.primary = .label
        appearance.primaryButton.backgroundColor = .label
        appearance.primaryButton.textColor = .systemBackground
        appearance.primaryButton.cornerRadius = 28
        appearance.cornerRadius = 12
        return appearance
    }
}

@available(iOS 16.0, *)
@MainActor
private final class CheckoutSheetResultRelay {
    var handleResult: ((CheckoutController.ConfirmResult) -> Void)?
}
