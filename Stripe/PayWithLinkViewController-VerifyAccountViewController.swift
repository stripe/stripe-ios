//
//  PayWithLinkViewController-VerifyAccountViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    final class VerifyAccountViewController: BaseViewController {

        private let linkAccount: PaymentSheetLinkAccount

        private let activityIndicator: ActivityIndicator = .init(size: .large)

        private lazy var twoFAViewController: Link2FAViewController = {
            let linkAccount = self.linkAccount

            let vc = Link2FAViewController(mode: .embedded, linkAccount: linkAccount) { [weak self] status in
                switch status {
                case .completed:
                    self?.coordinator?.accountUpdated(linkAccount)
                case .canceled:
                    self?.coordinator?.logout()
                }
            }

            vc.view.backgroundColor = .clear

            return vc
        }()

        init(linkAccount: PaymentSheetLinkAccount) {
            self.linkAccount = linkAccount
            super.init(nibName: nil, bundle: nil)

            addChild(twoFAViewController)
            contentView.addAndPinSubview(twoFAViewController.view, insets: .zero)

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(activityIndicator)

            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            guard !linkAccount.hasStartedSMSVerification else {
                return
            }

            activityIndicator.startAnimating()
            twoFAViewController.view.isHidden = true

            // TODO(ramont): Move this logic to `Link2FAViewController`.
            linkAccount.startVerification { [weak self] result in
                self?.activityIndicator.stopAnimating()
                self?.twoFAViewController.view.isHidden = false
                
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    STPAnalyticsClient.sharedClient.logLink2FAStartFailure()

                    // TODO(porter): Localize "Error" maybe? and invesitgate popping back to email view on this error
                    let alertController = UIAlertController(
                        title: "Error",
                        message: error.nonGenericDescription,
                        preferredStyle: .alert
                    )

                    alertController.addAction(UIAlertAction(
                        title: String.Localized.ok,
                        style: .default
                    ))

                    self?.dismiss(animated: true, completion: nil)
                    self?.navigationController?.present(alertController, animated: true)
                }
                
            }
        }

        override func onCloseButtonTapped(_ sender: UIButton) {
            super.onCloseButtonTapped(sender)
            STPAnalyticsClient.sharedClient.logLink2FACancel()
        }
    }

}
