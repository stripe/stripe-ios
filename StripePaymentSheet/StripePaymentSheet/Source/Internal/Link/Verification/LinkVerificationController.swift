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

        // Determine the verification flow (potentially with refresh)
        determineMobileFallbackURL { [weak self] url in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let url = url {
                    self.presentMobileFallbackWebview(from: presentingController, webviewUrl: url)
                } else {
                    presentingController.present(self.verificationViewController, animated: true)
                }
            }
        }
    }

    private func determineMobileFallbackURL(completion: @escaping (URL?) -> Void) {
        guard let mobileFallbackParams = linkAccount.currentSession?.mobileFallbackWebviewParams,
              let webviewUrl = mobileFallbackParams.webviewOpenUrl,
              mobileFallbackParams.webviewRequirementType == .required else {
            completion(nil)
            return
        }

        // Check if this URL was already visited
        if linkAccount.visitedFallbackURLs.contains(webviewUrl) {
            // Refresh to get a new URL
            linkAccount.refresh { [weak self] _ in
                guard let self = self else {
                    completion(nil)
                    return
                }

                // After refresh, get the new URL
                let newURL = Self.mobileFallbackURL(from: self.linkAccount)
                completion(newURL)
            }
        } else {
            // URL is fresh, use it directly
            completion(webviewUrl)
        }
    }

    private static func mobileFallbackURL(from linkAccount: PaymentSheetLinkAccount) -> URL? {
        guard let mobileFallbackParams = linkAccount.currentSession?.mobileFallbackWebviewParams,
              let webviewUrl = mobileFallbackParams.webviewOpenUrl,
              mobileFallbackParams.webviewRequirementType == .required else {
            return nil
        }
        return webviewUrl
    }

    private func presentMobileFallbackWebview(from presentingController: UIViewController, webviewUrl: URL) {
        // Mark this URL as visited
        linkAccount.visitedFallbackURLs.append(webviewUrl)

        let webviewController = LinkVerificationWebFallbackController(
            authenticationUrl: webviewUrl,
            presentingWindow: presentingController.view.window
        )
        webviewController.present { [weak self] result in
            guard let self = self else { return }

            // If verification completed successfully, refresh the session
            if case .completed = result {
                self.linkAccount.refresh { [weak self] _ in
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
