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
    func payWithLinkViewControllerDidShouldConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> Void
    )

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

    final class Context {
        let intent: Intent
        let configuration: PaymentSheet.Configuration
        var paymentMethodParams: STPPaymentMethodParams?
        var lastAddedPaymentDetails: ConsumerPaymentDetails?

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - configuration: PaymentSheet configuration.
        ///   - paymentMethodParams: If provided, Link will automatically save these payment details before showing the user's wallet.
        init(
            intent: Intent,
            configuration: PaymentSheet.Configuration,
            paymentMethodParams: STPPaymentMethodParams? = nil
        ) {
            self.intent = intent
            self.configuration = configuration
            self.paymentMethodParams = paymentMethodParams
        }
    }

    private(set) var linkAccount: PaymentSheetLinkAccount?

    private var context: Context

    weak var payWithLinkDelegate: PayWithLinkViewControllerDelegate?

    private var paymentIntent: STPPaymentIntent? {
        switch context.intent {
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

    convenience init(
        linkAccount: PaymentSheetLinkAccount?,
        intent: Intent,
        configuration: PaymentSheet.Configuration,
        paymentMethodParams: STPPaymentMethodParams? = nil
    ) {
        self.init(
            linkAccount: linkAccount,
            context: Context(
                intent: intent,
                configuration: configuration,
                paymentMethodParams: paymentMethodParams
            )
        )
    }

    private init(
        linkAccount: PaymentSheetLinkAccount?,
        context: Context
    ) {
        self.linkAccount = linkAccount
        self.context = context
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
                setRootViewController(
                    SignUpViewController(linkAccount: nil, context: context)
                )
            }
            return
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            if !(rootViewController is SignUpViewController) {
                setRootViewController(
                    SignUpViewController(linkAccount: linkAccount, context: context)
                )
            }
        case .requiresVerification:
            setRootViewController(VerifyAccountViewController(linkAccount: linkAccount))
        case .verified:
            setRootViewController(LoaderViewController())
            if let paymentMethodParams = context.paymentMethodParams {
                handlePaymentMethodParams(paymentMethodParams)
            } else {
                loadAndPresentWallet()
            }
        }
    }

}

private extension PayWithLinkViewController {

    func handlePaymentMethodParams(_ paymentMethodParams: STPPaymentMethodParams) {
        linkAccount?.createPaymentDetails(with: paymentMethodParams) { [weak self] details, _ in
            // TODO(ramont): error handling?
            self?.context.paymentMethodParams = nil
            self?.context.lastAddedPaymentDetails = details
            self?.loadAndPresentWallet()
        }
    }

    func loadAndPresentWallet() {
        guard let linkAccount = linkAccount else {
            assertionFailure("No link account is set")
            return
        }

        linkAccount.listPaymentDetails { (paymentDetails, error) in
            // TODO(ramont): error handling
            guard let paymentDetails = paymentDetails else {
                return
            }

            if paymentDetails.isEmpty {
                let addPaymentMethodVC = NewPaymentViewController(
                    linkAccount: linkAccount,
                    context: self.context
                )

                self.setRootViewController(addPaymentMethodVC)
            } else {
                let walletViewController = WalletViewController(
                    linkAccount: linkAccount,
                    context: self.context,
                    paymentMethods: paymentDetails
                )

                self.setRootViewController(walletViewController)
            }
        }
    }

}

// MARK: - Navigation

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

// MARK: - Coordinating

extension PayWithLinkViewController: PayWithLinkCoordinating {
    
    func confirm(with linkAccount: PaymentSheetLinkAccount, paymentDetails: ConsumerPaymentDetails, completion: @escaping (PaymentSheetResult) -> Void) {
        view.isUserInteractionEnabled = false

        payWithLinkDelegate?.payWithLinkViewControllerDidShouldConfirm(
            self,
            intent: context.intent,
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

