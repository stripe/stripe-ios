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
        elementsSession: STPElementsSession,
        with paymentOption: PaymentOption
    )

    func payWithLinkWebControllerDidCancel()

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
        let elementsSession: STPElementsSession
        let configuration: PaymentElementConfiguration
        let callToAction: ConfirmButton.CallToActionType
        var lastAddedPaymentDetails: ConsumerPaymentDetails?
        let alwaysUseEphemeralSession: Bool

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - elementsSession: STPElementsSession.
        ///   - configuration: PaymentElementConfiguration configuration.
        ///   - callToAction: A custom CTA to display on the confirm button. If `nil`, will display `intent`'s default CTA.
        ///   - alwaysUseEphemeralSession: If `true`, always use an ephemeral session. If `false`, we'll follow our existing ephemeral session logic.
        init(
            intent: Intent,
            elementsSession: STPElementsSession,
            configuration: PaymentElementConfiguration,
            callToAction: ConfirmButton.CallToActionType?,
            alwaysUseEphemeralSession: Bool
        ) {
            self.intent = intent
            self.elementsSession = elementsSession
            self.configuration = configuration
            self.callToAction = callToAction ?? intent.callToAction
            self.alwaysUseEphemeralSession = alwaysUseEphemeralSession
        }
    }

    private var context: Context

    weak var payWithLinkDelegate: PayWithLinkWebControllerDelegate?

    convenience init(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        callToAction: ConfirmButton.CallToActionType? = nil,
        alwaysUseEphemeralSession: Bool = false
    ) {
        self.init(
            context: Context(
                intent: intent,
                elementsSession: elementsSession,
                configuration: configuration,
                callToAction: callToAction,
                alwaysUseEphemeralSession: alwaysUseEphemeralSession
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
        STPAnalyticsClient.sharedClient.logLinkPopupShow(sessionType: self.context.elementsSession.linkPopupWebviewOption)
        do {
            // Generate Link URL, fetching the customer if needed
            let linkPopupParams = try LinkURLGenerator.linkParams(configuration: self.context.configuration, intent: self.context.intent, elementsSession: self.context.elementsSession)
            let linkPopupUrl = try LinkURLGenerator.url(params: linkPopupParams)

            let webAuthSession = ASWebAuthenticationSession(url: linkPopupUrl, callbackURLScheme: "link-popup") { returnURL, error in
                self.handleWebAuthenticationSessionCompletion(returnURL: returnURL, error: error)
            }

            // Check if we're in the ephemeral session experiment or we have an email address
            if self.context.elementsSession.linkPopupWebviewOption == .ephemeral || linkPopupParams.customerInfo.email != nil || context.alwaysUseEphemeralSession {
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
        STPAnalyticsClient.sharedClient.logLinkPopupCancel(sessionType: self.context.elementsSession.linkPopupWebviewOption)
        // If the user closed the popup, remove any Link account state.
        // Otherwise, a user would have to *log in* if they wanted to log out.
        // We don't have any account state at the moment. But if we did, we'd clear it here.
        self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel()
    }

    private func canceledWithError(error: Error?, returnURL: URL?) {
        STPAnalyticsClient.sharedClient.logLinkPopupError(error: error, returnURL: returnURL, sessionType: self.context.elementsSession.linkPopupWebviewOption)
        self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel()
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

                STPAnalyticsClient.sharedClient.logLinkPopupSuccess(sessionType: self.context.elementsSession.linkPopupWebviewOption)
                UserDefaults.standard.markLinkAsUsed()
                self.payWithLinkDelegate?.payWithLinkWebControllerDidComplete(self, intent: self.context.intent, elementsSession: self.context.elementsSession, with: paymentOption)
            case .logout:
                // Delete the account information
                STPAnalyticsClient.sharedClient.logLinkPopupLogout(sessionType: self.context.elementsSession.linkPopupWebviewOption)
                self.payWithLinkDelegate?.payWithLinkWebControllerDidCancel()
            }
        } catch {
            self.canceledWithError(error: error, returnURL: returnURL)
        }
    }
}
