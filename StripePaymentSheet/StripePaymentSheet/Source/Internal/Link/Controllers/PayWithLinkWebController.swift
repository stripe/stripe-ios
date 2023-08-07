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

protocol PayWithLinkWebControllerDelegate: AnyObject {

    func payWithLinkWebControllerDidComplete(
        _ payWithLinkWebController: PayWithLinkWebController,
        intent: Intent,
        with paymentOption: PaymentOption
    )

    func payWithLinkWebControllerDidCancel(_ payWithLinkWebController: PayWithLinkWebController)

}

protocol PayWithLinkCoordinating: AnyObject {
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails
    )
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func logout(cancel: Bool)
}

/// A view controller for paying with Link using ASWebAuthenticationSession.
///
/// Instantiate and present this controller when the user chooses to pay with Link.
/// For internal SDK use only

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

    func present(over viewController: UIViewController? = nil) {
        STPAnalyticsClient.sharedClient.logLinkPopupShow(sessionType: self.context.intent.linkPopupWebviewOption)
        Task { @MainActor in
            do {
                // Generate Link URL, fetching the customer if needed
                let linkPopupUrl = try await LinkURLGenerator.url(configuration: self.context.configuration, intent: self.context.intent)

                let webAuthSession = ASWebAuthenticationSession(url: linkPopupUrl, callbackURLScheme: "link-popup") { returnURL, error in
                    self.handleWebAuthenticationSessionCompletion(returnURL: returnURL, error: error)
                }

                // Check if we're in the ephemeral session experiment
                if self.context.intent.linkPopupWebviewOption == .ephemeral {
                    webAuthSession.prefersEphemeralWebBrowserSession = true
                }

                // Set up presentation
                self.presentationVC = viewController
                webAuthSession.presentationContextProvider = self

                self.webAuthSession = webAuthSession
                webAuthSession.start()
            } catch {
                self.canceledWithError(error: error)
            }
        }
    }

    private func canceledWithoutError() {
        STPAnalyticsClient.sharedClient.logLinkPopupCancel(sessionType: self.context.intent.linkPopupWebviewOption)
//      If the user closed the popup, remove any Link account state.
//      Otherwise, a user would have to *log in* if they wanted to log out.
        LinkAccountService.defaultCookieStore.clear()
        self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
    }

    private func canceledWithError(error: Error?) {
        STPAnalyticsClient.sharedClient.logLinkPopupError(error: error, sessionType: self.context.intent.linkPopupWebviewOption)
        self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
    }

    private func handleWebAuthenticationSessionCompletion(returnURL: URL?, error: Error?) {
        guard let returnURL = returnURL else {
            if let error = error as? NSError,
               error.domain == ASWebAuthenticationSessionErrorDomain,
               error.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                self.canceledWithoutError()
            } else {
                // Canceled for another reason - raise an error.
                self.canceledWithError(error: error)
            }
            return
        }
        do {
            let result = try LinkPopupURLParser.result(with: returnURL)
            switch result.link_status {
            case .complete:
                let paymentOption = PaymentOption.link(option: PaymentSheet.LinkConfirmOption.withPaymentMethod(paymentMethod: result.pm))

                // Cache the PM details
                let las = LinkAccountService()
                las.setLastPMDetails(pm: result.pm)

                STPAnalyticsClient.sharedClient.logLinkPopupSuccess(sessionType: self.context.intent.linkPopupWebviewOption)
                self.payWithLinkDelegate?.payWithLinkWebControllerDidComplete(self, intent: self.context.intent, with: paymentOption)
            case .logout:
                // Delete the account information
                LinkAccountService.defaultCookieStore.clear()
                STPAnalyticsClient.sharedClient.logLinkPopupLogout(sessionType: self.context.intent.linkPopupWebviewOption)
                self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
            }
        } catch {
            self.canceledWithError(error: error)
        }
    }
}

// MARK: - Coordinating

extension PayWithLinkWebController: PayWithLinkCoordinating {

    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails
    ) {
        payWithLinkDelegate?.payWithLinkWebControllerDidComplete(
            self,
            intent: context.intent,
            with: PaymentOption.link(
                option: .withPaymentDetails(account: linkAccount, paymentDetails: paymentDetails)
            )
        )
    }

    func cancel() {
        webAuthSession?.cancel()
        payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
    }

    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {
        self.linkAccount = linkAccount
    }

    func logout(cancel: Bool) {
        linkAccount?.logout()
        linkAccount = nil

        if cancel {
            self.cancel()
        }
    }

}
