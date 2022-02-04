//
//  PayWithLinkViewController.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 9/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

import SafariServices

protocol PayWithLinkViewControllerDelegate: AnyObject {
    func payWithLinkViewControllerDidShouldConfirm(_ payWithLinkViewController: PayWithLinkViewController,
                                                   with paymentOption: PaymentOption,
                                                   completion: @escaping (PaymentSheetResult) -> Void)
    
    func payWithLinkViewControllerDidUpdateLinkAccount(_ payWithLinkViewController: PayWithLinkViewController, linkAccount: PaymentSheetLinkAccount?)
    
    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController)
    
    func payWithLinkViewControllerDidFinish(_ payWithLinkViewController: PayWithLinkViewController, result: PaymentSheetResult)
}

protocol PayWithLinkCoordinating: AnyObject {
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func confirm(with linkAccount: PaymentSheetLinkAccount, paymentDetails: ConsumerPaymentDetails, completion: @escaping (PaymentSheetResult) -> Void)
    func finish(withResult result: PaymentSheetResult)
    func logout()
}

/// A view controller for paying with Link.
///
/// Instantiate and present this controller when the user chooses to pay with Link.
/// For internal SDK use only
@objc(STP_Internal_PayWithLinkViewController)
final class PayWithLinkViewController: UINavigationController {

    private(set) var linkAccount: PaymentSheetLinkAccount?
    let intent: Intent
    let configuration: PaymentSheet.Configuration

    weak var payWithLinkDelegate: PayWithLinkViewControllerDelegate?

    private var paymentIntent: STPPaymentIntent? {
        switch intent {
        case .paymentIntent(let paymentIntent):
            return paymentIntent
        case .setupIntent(_):
            assertionFailure() // TODO(csabol): Link for setup intents
            return nil
        }
    }
    private var isShowingLoader: Bool {
        guard let rootViewController = viewControllers.first else {
            return false
        }

        return rootViewController is LoaderViewController
    }

    init(
        linkAccount: PaymentSheetLinkAccount?,
        intent: Intent,
        configuration: PaymentSheet.Configuration
    ) {
        self.linkAccount = linkAccount
        self.intent = intent
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)

        // Show loader
        setRootViewController(LoaderViewController(), animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.applyLinkTheme()
        view.tintColor = .linkBrand
        updateUI()
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? BaseViewController {
            viewController.coordinator = self
        }

        super.pushViewController(viewController, animated: animated)
    }

    private func updateUI() {
        guard let linkAccount = linkAccount else {
            if !(rootViewController is SignUpViewController) {
                setRootViewController(SignUpViewController(
                    configuration: configuration,
                    linkAccount: nil,
                    intent: intent
                ))
            }
            return
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            if !(rootViewController is SignUpViewController) {
                setRootViewController(SignUpViewController(
                    configuration: configuration,
                    linkAccount: linkAccount,
                    intent: intent
                ))
            }
        case .requiresVerification:
            setRootViewController(VerifyAccountViewController(linkAccount: linkAccount))
        case .verified:
            setRootViewController(LoaderViewController())
            linkAccount.listPaymentDetails { (paymentDetails, error) in
                // TODO(ramont): error handling
                guard let paymentDetails = paymentDetails else {
                    return
                }
                
                if paymentDetails.isEmpty {
                    let addPaymentMethodVC = NewPaymentViewController(
                        linkAccount: linkAccount,
                        intent: self.intent,
                        configuration: self.configuration
                    )

                    self.setRootViewController(addPaymentMethodVC)
                } else {
                    let walletViewController = WalletViewController(
                        linkAccount: linkAccount,
                        intent: self.intent,
                        configuration: self.configuration,
                        paymentMethods: paymentDetails
                    )

                    self.setRootViewController(walletViewController)
                }
            }
        }
    }

}

private extension PayWithLinkViewController {

    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        if let viewController = viewController as? BaseViewController {
            viewController.coordinator = self
        }

        setViewControllers([viewController], animated: isShowingLoader ? false : animated)
    }
    
    var rootViewController: UIViewController? {
        return viewControllers.first
    }

}

extension PayWithLinkViewController: PayWithLinkCoordinating {
    
    func confirm(with linkAccount: PaymentSheetLinkAccount, paymentDetails: ConsumerPaymentDetails, completion: @escaping (PaymentSheetResult) -> Void) {
        view.isUserInteractionEnabled = false

        payWithLinkDelegate?.payWithLinkViewControllerDidShouldConfirm(
            self,
            with: PaymentOption.link(account: linkAccount,
                                     option: .withPaymentDetails(paymentDetails: paymentDetails))
        ) { [weak self] result in
            self?.view.isUserInteractionEnabled = true
            completion(result)
        }
    }

    func cancel() {
        payWithLinkDelegate?.payWithLinkViewControllerDidCancel(self)
    }

    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {
        self.linkAccount = linkAccount
        payWithLinkDelegate?.payWithLinkViewControllerDidUpdateLinkAccount(self, linkAccount: linkAccount)
        updateUI()
    }

    func finish(withResult result: PaymentSheetResult) {
        view.isUserInteractionEnabled = false
        payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, result: result)
    }

    func logout() {
        linkAccount?.logout()
        linkAccount = nil
        payWithLinkDelegate?.payWithLinkViewControllerDidUpdateLinkAccount(self, linkAccount: linkAccount)
        updateUI()
    }

}

