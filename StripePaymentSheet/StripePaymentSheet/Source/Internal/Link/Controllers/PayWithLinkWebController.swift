//
//  PayWithLinkWebController.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 9/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

import AuthenticationServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol PayWithLinkWebControllerDelegate: AnyObject {

    func payWithLinkWebControllerDidConfirm(
        _ payWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> Void
    )

    func payWithLinkWebControllerDidCancel(_ payWithLinkWebController: PayWithLinkWebController)

    func payWithLinkWebControllerDidFinish(
        _ payWithLinkWebController: PayWithLinkWebController,
        result: PaymentSheetResult
    )

}

protocol PayWithLinkCoordinating: AnyObject {
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        completion: @escaping (PaymentSheetResult) -> Void
    )
    func confirmWithApplePay()
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func finish(withResult result: PaymentSheetResult)
    func logout(cancel: Bool)
}

/// A view controller for paying with Link using ASWebAuthenticationSession.
///
/// Instantiate and present this controller when the user chooses to pay with Link.
/// For internal SDK use only

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@objc(STP_Internal_PayWithLinkWebController)
final class PayWithLinkWebController: NSObject, ASWebAuthenticationPresentationContextProviding, STPAuthenticationContext {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return bestWindowForPresentation
    }
    func authenticationPresentingViewController() -> UIViewController {
        if let presentationVC = presentationVC {
            return presentationVC
        }
        let window = bestWindowForPresentation
        var presentingViewController: UIViewController = window.rootViewController!

        // Find the most-presented UIViewController
        while let presented = presentingViewController.presentedViewController {
            presentingViewController = presented
        }

        return presentingViewController
    }
    var bestWindowForPresentation: UIWindow {
        if let window = presentationVC?.view.window {
            return window
        }
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIApplication.shared.windows.first!
    }
    var presentationVC: UIViewController?

    enum LinkAccountError: Error {
        case noLinkAccount

        var localizedDescription: String {
            "No Link account is set"
        }
    }

    final class Context {
        let intent: Intent
        let configuration: PaymentSheet.Configuration
        let shouldOfferApplePay: Bool
        let shouldFinishOnClose: Bool
        let callToAction: ConfirmButton.CallToActionType
        var lastAddedPaymentDetails: ConsumerPaymentDetails?

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - configuration: PaymentSheet configuration.
        ///   - shouldOfferApplePay: Whether or not to show Apple Pay as a payment option.
        ///   - shouldFinishOnClose: Whether or not Link should finish with `.canceled` result instead of returning to Payment Sheet when the close button is tapped.
        ///   - callToAction: A custom CTA to display on the confirm button. If `nil`, will display `intent`'s default CTA.
        init(
            intent: Intent,
            configuration: PaymentSheet.Configuration,
            shouldOfferApplePay: Bool,
            shouldFinishOnClose: Bool,
            callToAction: ConfirmButton.CallToActionType?
        ) {
            self.intent = intent
            self.configuration = configuration
            self.shouldOfferApplePay = shouldOfferApplePay
            self.shouldFinishOnClose = shouldFinishOnClose
            self.callToAction = callToAction ?? intent.callToAction
        }
    }

    private var context: Context
    private var accountContext: LinkAccountContext = .shared

    private var linkAccount: PaymentSheetLinkAccount? {
        get { accountContext.account }
        set { accountContext.account = newValue }
    }

    weak var payWithLinkDelegate: PayWithLinkWebControllerDelegate?

    convenience init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        shouldOfferApplePay: Bool = false,
        shouldFinishOnClose: Bool = false,
        callToAction: ConfirmButton.CallToActionType? = nil
    ) {
        self.init(
            context: Context(
                intent: intent,
                configuration: configuration,
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: shouldFinishOnClose,
                callToAction: callToAction
            )
        )
    }

    private init(context: Context) {
        self.context = context
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var webAuthSession: ASWebAuthenticationSession?

    /// Defaults to the app's key window
    func present(over viewController: UIViewController? = nil) {
        Task { @MainActor in
            // TODO: Log attempt to show web session
            do {
                let linkPopupUrl = try await LinkURLGenerator.url(configuration: self.context.configuration, intent: self.context.intent)
                let webAuthSession = ASWebAuthenticationSession(url: linkPopupUrl, callbackURLScheme: "link-popup") { returnURL, error in
                    guard let returnURL = returnURL else {
                        // TODO: Get analytics logs here: Did the user start a session and then reject the non-ephemeralSession dialog? ASWebAuthenticationSession.cancelledLogin error
                        return
                    }
                    do {
                        // TODO: Log that authentication session succeeded
                        let result = try LinkPopupURLParser.result(with: returnURL)
                        // TODO: Do something with the result
                        print(result)
                    } catch {
                        // TODO: Send analytics error here
                        print(error)
                    }
                }
                self.presentationVC = viewController
                webAuthSession.presentationContextProvider = self
                self.webAuthSession = webAuthSession
                webAuthSession.start()
            } catch {
                // Handle errors (including LinkURLParams errors)
            }
        }
    }
}

// MARK: - Coordinating

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PayWithLinkWebController: PayWithLinkCoordinating {

    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        payWithLinkDelegate?.payWithLinkWebControllerDidConfirm(
            self,
            intent: context.intent,
            with: PaymentOption.link(
                option: .withPaymentDetails(account: linkAccount, paymentDetails: paymentDetails)
            )
        ) { result in
            completion(result)
        }
    }

    func confirmWithApplePay() {
        payWithLinkDelegate?.payWithLinkWebControllerDidConfirm(
            self,
            intent: context.intent,
            with: .applePay
        ) { [weak self] result in
            switch result {
            case .canceled:
                // no-op -- we don't dismiss/finish for canceled Apple Pay interactions
                break
            case .completed, .failed:
                self?.finish(withResult: result)
            }
        }
    }

    func cancel() {
        webAuthSession?.cancel()
        payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
    }

    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {
        self.linkAccount = linkAccount
    }

    func finish(withResult result: PaymentSheetResult) {
        payWithLinkDelegate?.payWithLinkWebControllerDidFinish(self, result: result)
    }

    func logout(cancel: Bool) {
        linkAccount?.logout()
        linkAccount = nil

        if cancel {
            self.cancel()
        }
    }

}
