//
//  PayWithLinkViewController-SignUpViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import SafariServices
import UIKit

@_spi(STP) import StripeCore
@_exported @_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PayWithLinkSignUpViewController)
    final class SignUpViewController: BaseViewController {

        private let linkAccount: PaymentSheetLinkAccount?

        private lazy var signUpVC: LinkSignUpViewController = {
            let accountService = LinkAccountService(apiClient: context.configuration.apiClient, elementsSession: context.elementsSession)
            let vc = LinkSignUpViewController(
                accountService: accountService,
                linkAccount: linkAccount,
                legalName: nil,
                country: context.elementsSession.countryCode,
                defaultBillingDetails: context.configuration.defaultBillingDetails,
                billingDetailsCollectionConfiguration: context.configuration.billingDetailsCollectionConfiguration
            )
            vc.delegate = self
            vc.view.backgroundColor = .clear
            return vc
        }()

        init(
            linkAccount: PaymentSheetLinkAccount?,
            context: Context
        ) {
            self.linkAccount = linkAccount
            super.init(context: context)

            addChild(signUpVC)
            contentView.addSubview(signUpVC.view)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            signUpVC.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: signUpVC.view.topAnchor),
                contentView.leadingAnchor.constraint(equalTo: signUpVC.view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: signUpVC.view.trailingAnchor),
                contentView.bottomAnchor.constraint(greaterThanOrEqualTo: signUpVC.view.bottomAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            ])
        }

        override var requiresFullScreen: Bool { true }

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
        // Error handling is already done in the standalone controller
    }

    func signUpControllerDidCancel(_ controller: LinkSignUpViewController) {
        // Handle cancellation if needed
    }

    func signUpControllerDidEncounterAttestationError(_ controller: LinkSignUpViewController) {
        coordinator?.bailToWebFlow()
    }
}
