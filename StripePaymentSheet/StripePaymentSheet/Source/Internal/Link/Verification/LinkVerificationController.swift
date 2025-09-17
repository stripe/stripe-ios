//
//  LinkVerificationController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// Standalone verification controller.
final class LinkVerificationController {

    typealias CompletionBlock = (LinkVerificationViewController.VerificationResult) -> Void

    private var completion: CompletionBlock?

    private var selfRetainer: LinkVerificationController?
    private let verificationViewController: LinkVerificationViewController
    private let linkAccount: PaymentSheetLinkAccount

    init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        configuration: PaymentElementConfiguration,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false,
        consentViewModel: LinkConsentViewModel? = nil
    ) {
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)

        self.linkAccount = linkAccount
        self.verificationViewController = LinkVerificationViewController(
            mode: mode,
            linkAccount: linkAccount,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel
        )
        verificationViewController.delegate = self
        configuration.style.configure(verificationViewController)
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        self.selfRetainer = self
        self.completion = completion

        // Check if mobile fallback webview should be used
        if let url = mobileFallbackURLIfNeeded() {
            presentMobileFallbackWebview(from: presentingController, webviewUrl: url)
        } else {
            presentingController.present(verificationViewController, animated: true)
        }
    }

    private func mobileFallbackURLIfNeeded() -> URL? {
        guard let mobileFallbackParams = linkAccount.currentSession?.mobileFallbackWebviewParams,
              let webviewUrl = mobileFallbackParams.webviewOpenUrl,
              mobileFallbackParams.webviewRequirementType == .required else {
            return nil
        }
        return webviewUrl
    }

    private func presentMobileFallbackWebview(from presentingController: UIViewController, webviewUrl: URL) {
        let webviewController = LinkVerificationWebFallbackController(
            authenticationUrl: webviewUrl,
            presentingWindow: presentingController.view.window
        )
        webviewController.present { [weak self] result in
            guard let self = self else { return }

            // If verification completed successfully, refresh the session
            if case .completed = result {
                self.linkAccount.refresh { [weak self] refreshResult in
                    self?.completion?(result)
                    self?.selfRetainer = nil
                }
            } else {
                self.completion?(result)
                self.selfRetainer = nil
            }
        }
    }

}

extension LinkVerificationController: LinkVerificationViewControllerDelegate {

    func verificationController(
        _ controller: LinkVerificationViewController,
        didFinishWithResult result: LinkVerificationViewController.VerificationResult
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.completion?(result)
            self?.selfRetainer = nil
        }
    }

}
