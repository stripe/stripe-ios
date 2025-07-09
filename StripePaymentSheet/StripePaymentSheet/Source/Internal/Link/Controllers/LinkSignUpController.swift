//
//  LinkSignUpController.swift
//  StripePaymentSheet
//
//  Created by Assistant on 1/6/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Standalone signup controller.
final class LinkSignUpController {
    enum Style {
        case automatic
        case alwaysLight
        case alwaysDark
    }

    enum SignUpResult {
        /// Sign up was completed successfully.
        case completed(PaymentSheetLinkAccount)
        /// Sign up was canceled by the user.
        case canceled
        /// Sign up failed due to an unrecoverable error.
        case failed(Error)
        /// Sign up encountered an attestation error and should bail to web flow.
        case attestationError
    }

    typealias CompletionBlock = (SignUpResult) -> Void

    private var completion: CompletionBlock?
    private var selfRetainer: LinkSignUpController?
    private let signUpViewController: LinkSignUpViewController

    init(
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount?,
        legalName: String?,
        country: String?,
        defaultBillingDetails: PaymentSheet.BillingDetails = PaymentSheet.BillingDetails(),
        billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration(),
        configuration: PaymentElementConfiguration
    ) {
        self.signUpViewController = LinkSignUpViewController(
            accountService: accountService,
            linkAccount: linkAccount,
            legalName: legalName,
            country: country,
            defaultBillingDetails: defaultBillingDetails,
            billingDetailsCollectionConfiguration: billingDetailsCollectionConfiguration
        )
        signUpViewController.delegate = self
        configuration.style.configure(signUpViewController)
    }

    init(
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount?,
        legalName: String?,
        country: String?,
        defaultBillingDetails: PaymentSheet.BillingDetails = PaymentSheet.BillingDetails(),
        billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration(),
        style: Style = .automatic
    ) {
        self.signUpViewController = LinkSignUpViewController(
            accountService: accountService,
            linkAccount: linkAccount,
            legalName: legalName,
            country: country,
            defaultBillingDetails: defaultBillingDetails,
            billingDetailsCollectionConfiguration: billingDetailsCollectionConfiguration
        )
        signUpViewController.delegate = self

        let paymentSheetStyle: PaymentSheet.UserInterfaceStyle
        switch style {
        case .automatic: paymentSheetStyle = .automatic
        case .alwaysLight: paymentSheetStyle = .alwaysLight
        case .alwaysDark: paymentSheetStyle = .alwaysDark
        }
        paymentSheetStyle.configure(signUpViewController)
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        self.selfRetainer = self
        self.completion = completion
        presentingController.present(signUpViewController, animated: true)
    }

}

extension LinkSignUpController: LinkSignUpViewControllerDelegate {

    func signUpController(
        _ controller: LinkSignUpViewController,
        didCompleteSignUpWith linkAccount: PaymentSheetLinkAccount
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.completion?(.completed(linkAccount))
            self?.selfRetainer = nil
        }
    }

    func signUpController(
        _ controller: LinkSignUpViewController,
        didFailWithError error: Error
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.completion?(.failed(error))
            self?.selfRetainer = nil
        }
    }

    func signUpControllerDidCancel(_ controller: LinkSignUpViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.completion?(.canceled)
            self?.selfRetainer = nil
        }
    }

    func signUpControllerDidEncounterAttestationError(_ controller: LinkSignUpViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.completion?(.attestationError)
            self?.selfRetainer = nil
        }
    }

}
