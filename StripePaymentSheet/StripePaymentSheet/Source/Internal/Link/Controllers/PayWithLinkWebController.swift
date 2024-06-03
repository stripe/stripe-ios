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
        return UIApplication.shared.stp_hackilyFumbleAroundUntilYouFindAKeyWindow()!
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
        let callToAction: ConfirmButton.CallToActionType
        var lastAddedPaymentDetails: ConsumerPaymentDetails?

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - configuration: PaymentSheet configuration.
        ///   - callToAction: A custom CTA to display on the confirm button. If `nil`, will display `intent`'s default CTA.
        init(
            intent: Intent,
            configuration: PaymentSheet.Configuration,
            callToAction: ConfirmButton.CallToActionType?
        ) {
            self.intent = intent
            self.configuration = configuration
            self.callToAction = callToAction ?? intent.callToAction
        }
    }

    private var context: Context

    weak var payWithLinkDelegate: PayWithLinkWebControllerDelegate?

    convenience init(
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        callToAction: ConfirmButton.CallToActionType? = nil
    ) {
        self.init(
            context: Context(
                intent: intent,
                configuration: configuration,
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
        do {
            // Generate Link URL, fetching the customer if needed
            let linkPopupParams = try LinkURLGenerator.linkParams(configuration: self.context.configuration, intent: self.context.intent)
            let linkPopupUrl = try LinkURLGenerator.url(params: linkPopupParams)

            let webAuthSession = ASWebAuthenticationSession(url: linkPopupUrl, callbackURLScheme: "link-popup") { returnURL, error in
                self.handleWebAuthenticationSessionCompletion(returnURL: returnURL, error: error)
            }

            // Check if we're in the ephemeral session experiment or we have an email address
            if self.context.intent.linkPopupWebviewOption == .ephemeral || linkPopupParams.customerInfo.email != nil {
                webAuthSession.prefersEphemeralWebBrowserSession = true
            }

            // Set up presentation
            self.presentationVC = viewController
            webAuthSession.presentationContextProvider = self

            self.webAuthSession = webAuthSession
            webAuthSession.start()
        } catch {
            self.canceledWithError(error: error, returnURL: nil)
        }
    }

    private func canceledWithoutError() {
        STPAnalyticsClient.sharedClient.logLinkPopupCancel(sessionType: self.context.intent.linkPopupWebviewOption)
        // If the user closed the popup, remove any Link account state.
        // Otherwise, a user would have to *log in* if they wanted to log out.
        // We don't have any account state at the moment. But if we did, we'd clear it here.
        self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
    }

    private func canceledWithError(error: Error?, returnURL: URL?) {
        STPAnalyticsClient.sharedClient.logLinkPopupError(error: error, returnURL: returnURL, sessionType: self.context.intent.linkPopupWebviewOption)
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
                self.canceledWithError(error: error, returnURL: returnURL)
            }
            return
        }
        do {
            let result = try LinkPopupURLParser.result(with: returnURL)
            switch result {
            case .complete(let pm):
                let paymentOption = PaymentOption.link(option: PaymentSheet.LinkConfirmOption.withPaymentMethod(paymentMethod: pm))

                STPAnalyticsClient.sharedClient.logLinkPopupSuccess(sessionType: self.context.intent.linkPopupWebviewOption)
                UserDefaults.standard.markLinkAsUsed()
                self.payWithLinkDelegate?.payWithLinkWebControllerDidComplete(self, intent: self.context.intent, with: paymentOption)
            case .logout:
                // Delete the account information
                STPAnalyticsClient.sharedClient.logLinkPopupLogout(sessionType: self.context.intent.linkPopupWebviewOption)
                self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel(self)
            }
        } catch {
            self.canceledWithError(error: error, returnURL: returnURL)
        }
    }
}
