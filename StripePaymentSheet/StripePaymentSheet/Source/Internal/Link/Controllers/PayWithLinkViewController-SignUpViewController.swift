//
//  PayWithLinkViewController-SignUpViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PayWithLinkSignUpViewController)
    final class SignUpViewController: BaseViewController {

        private let linkAccount: PaymentSheetLinkAccount?

        override var requiresFullScreen: Bool { true }

        private lazy var signUpViewController: LinkSignUpViewController = {
            let accountService = LinkAccountService(apiClient: context.configuration.apiClient, elementsSession: context.elementsSession)
            let viewController = LinkSignUpViewController(
                accountService: accountService,
                linkAccount: linkAccount,
                country: context.elementsSession.countryCode,
                defaultBillingDetails: context.configuration.defaultBillingDetails
            )
            viewController.delegate = self
            viewController.view.backgroundColor = .clear
            return viewController
        }()

        init(
            linkAccount: PaymentSheetLinkAccount?,
            context: Context
        ) {
            self.linkAccount = linkAccount
            super.init(context: context)

            addChild(signUpViewController)
            contentView.addSubview(signUpViewController.view)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            signUpViewController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: signUpViewController.view.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: signUpViewController.view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: signUpViewController.view.trailingAnchor),
                contentView.bottomAnchor.constraint(greaterThanOrEqualTo: signUpViewController.view.bottomAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            ])
        }

    }

}

extension PayWithLinkViewController.SignUpViewController: LinkSignUpViewControllerDelegate {
    func signUpController(
        _ controller: LinkSignUpViewController,
        didCompleteSignUpWith linkAccount: PaymentSheetLinkAccount
    ) {
        coordinator?.accountUpdated(linkAccount)
    }

    func signUpController(
        _ controller: LinkSignUpViewController,
        didFailWithError error: Error
    ) {
        // No-op: Error handling is already done in the standalone controller + view model.
    }

    func signUpControllerDidCancel(_ controller: LinkSignUpViewController) {
        // No-op: BaseViewController handles cancelling the flow.
    }

    func signUpControllerDidEncounterAttestationError(_ controller: LinkSignUpViewController) {
        coordinator?.bailToWebFlow()
    }
}
