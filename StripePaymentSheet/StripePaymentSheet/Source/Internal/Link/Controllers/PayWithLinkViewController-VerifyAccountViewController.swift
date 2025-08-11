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

        private lazy var verificationVC: LinkVerificationViewController = {
            let vc = LinkVerificationViewController(mode: .embedded, linkAccount: linkAccount)
            vc.delegate = self
            vc.view.backgroundColor = .clear
            return vc
        }()

        init(linkAccount: PaymentSheetLinkAccount, context: Context) {
            self.linkAccount = linkAccount
            super.init(context: context)

            addChild(verificationVC)

            contentView.addSubview(verificationVC.view)
        }

        override var requiresFullScreen: Bool { true }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            verificationVC.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: verificationVC.view.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: verificationVC.view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: verificationVC.view.trailingAnchor),
                contentView.bottomAnchor.constraint(greaterThanOrEqualTo: verificationVC.view.bottomAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            ])
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
        switch result {
        case .completed:
            coordinator?.accountUpdated(linkAccount)
        case .canceled, .switchAccount:
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

}
