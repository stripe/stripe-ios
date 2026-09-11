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
        private var dismissedFromSheet = false

        private lazy var authController: LinkAuthFlowViewController = {
            let controller = LinkAuthFlowViewController(
                mode: .embedded,
                linkAccount: linkAccount,
                brand: context.linkBrand,
                appearance: context.linkAppearance
            )
            controller.onFinish = { [weak self] result in self?.handleVerificationResult(result) }
            controller.onNavigationUpdate = { [weak self] in
                guard let self else { return }
                self.navigationBar.setStyle(
                    self.authController.coordinator.showsBackButton
                    ? .back(showAdditionalButton: false)
                    : .close(showAdditionalButton: false)
                )
            }
            return controller
        }()

        init(linkAccount: PaymentSheetLinkAccount, context: Context) {
            self.linkAccount = linkAccount
            super.init(context: context)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override var requiresFullScreen: Bool { true }

        override func viewDidLoad() {
            super.viewDidLoad()
            addChild(authController)
            contentView.addSubview(authController.view)
            authController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                authController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                authController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                authController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                authController.view.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            ])
            authController.didMove(toParent: self)
        }

        func goBackInAuthentication() { authController.back() }

        override func didTapOrSwipeToDismiss() {
            dismissedFromSheet = true
            authController.close()
        }

        private func handleVerificationResult(_ result: LinkVerificationResult) {
            switch result {
            case .completed:
                coordinator?.accountUpdated(linkAccount)
            case .canceled:
                if dismissedFromSheet {
                    super.didTapOrSwipeToDismiss()
                } else if authController.didPresentWebFallback {
                    coordinator?.cancel(shouldReturnToPaymentSheet: true)
                } else {
                    coordinator?.logout(cancel: false)
                }
            case .switchAccount:
                coordinator?.logout(cancel: false)
            case .failed(let error):
                let alert = UIAlertController(
                    title: String.Localized.error,
                    message: error.nonGenericDescription,
                    preferredStyle: .alert
                )
                alert.addAction(
                    UIAlertAction(
                        title: String.Localized.ok,
                        style: .default
                    ) { [weak self] _ in
                        self?.coordinator?.logout(cancel: false)
                    }
                )
                present(alert, animated: true)
            }
        }
    }
}
