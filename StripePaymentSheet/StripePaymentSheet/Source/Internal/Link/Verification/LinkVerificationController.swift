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

    init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        configuration: PaymentElementConfiguration
    ) {
        self.verificationViewController = LinkVerificationViewController(mode: mode, linkAccount: linkAccount)
        verificationViewController.delegate = self
        configuration.style.configure(verificationViewController)
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        self.selfRetainer = self
        self.completion = completion
        presentingController.present(verificationViewController, animated: true)
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
