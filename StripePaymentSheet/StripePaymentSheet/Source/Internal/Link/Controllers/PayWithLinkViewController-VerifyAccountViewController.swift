//
//  PayWithLinkViewController-VerifyAccountViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension PayWithLinkViewController {

    final class VerifyAccountViewController: BaseViewController {

        private let linkAccount: PaymentSheetLinkAccount
        private var isUsingWebviewFallback: Bool = false

        private lazy var verificationVC: LinkVerificationViewController = {
            let vc = LinkVerificationViewController(mode: .embedded, linkAccount: linkAccount)
            vc.delegate = self
            vc.view.backgroundColor = .clear
            return vc
        }()

        init(linkAccount: PaymentSheetLinkAccount, context: Context) {
            self.linkAccount = linkAccount
            super.init(context: context)
        }

        override var requiresFullScreen: Bool { true }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            // Determine the verification flow (potentially with refresh)
            determineMobileFallbackURL { [weak self] url in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let url = url {
                        self.isUsingWebviewFallback = true
                        self.presentMobileFallbackWebview(url: url)
                    } else {
                        self.isUsingWebviewFallback = false
                        self.setupEmbeddedVerification()
                    }
                }
            }
        }

        private func setupEmbeddedVerification() {
            addChild(verificationVC)
            contentView.addSubview(verificationVC.view)

            verificationVC.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: verificationVC.view.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: verificationVC.view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: verificationVC.view.trailingAnchor),
                contentView.bottomAnchor.constraint(greaterThanOrEqualTo: verificationVC.view.bottomAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            ])
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
                    guard let self else {
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

        private func presentMobileFallbackWebview(url: URL) {
            // Mark this URL as visited
            linkAccount.visitedFallbackURLs.append(url)

            let webviewController = LinkVerificationWebFallbackController(
                authenticationUrl: url,
                presentingWindow: view.window
            )

            webviewController.present { [weak self] result in
                guard let self else { return }

                // If verification completed successfully, refresh the session
                if case .completed = result {
                    self.linkAccount.refresh { [weak self] _ in
                        self?.handleVerificationResult(result)
                    }
                } else {
                    self.handleVerificationResult(result)
                }
            }
        }

        private func handleVerificationResult(_ result: LinkVerificationViewController.VerificationResult) {
            switch result {
            case .completed:
                coordinator?.accountUpdated(linkAccount)
            case .canceled:
                if isUsingWebviewFallback {
                    // Webview was canceled - return to payment sheet
                    coordinator?.cancel(shouldReturnToPaymentSheet: true)
                } else {
                    // Embedded verification was canceled - logout
                    coordinator?.logout(cancel: false)
                }
            case .switchAccount:
                coordinator?.logout(cancel: false)
            case .failed(let error):
                let alertController = UIAlertController(
                    title: String.Localized.error,
                    message: error.nonGenericDescription,
                    preferredStyle: .alert
                )

                alertController.addAction(UIAlertAction(
                    title: String.Localized.ok,
                    style: .default,
                    handler: { [weak self] _ in
                        self?.coordinator?.logout(cancel: false)
                    }
                ))

                navigationController?.present(alertController, animated: true)
            }
        }

        override func didTapOrSwipeToDismiss() {
            super.didTapOrSwipeToDismiss()
            STPAnalyticsClient.sharedClient.logLink2FACancel()
        }
    }
}

extension PayWithLinkViewController.VerifyAccountViewController: LinkVerificationViewControllerDelegate {

    func verificationController(
        _ controller: LinkVerificationViewController,
        didFinishWithResult result: LinkVerificationViewController.VerificationResult
    ) {
        handleVerificationResult(result)
    }

}
