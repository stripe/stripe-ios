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
    
    func payWithLinkViewControllerDidSelectPaymentOption(_ payWithLinkViewController: PayWithLinkViewController, paymentOption: PaymentOption)
}

protocol PayWithLinkCoordinating: AnyObject {
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func confirm(with linkAccount: PaymentSheetLinkAccount, paymentDetails: ConsumerPaymentDetails, completion: @escaping (PaymentSheetResult) -> Void)
    func confirmWithApplePay()
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
        let selectionOnly: Bool
        let shouldOfferApplePay: Bool
        var lastAddedPaymentDetails: ConsumerPaymentDetails?

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - configuration: PaymentSheet configuration.
        ///   - selectionOnly: :nodoc:
        ///   - shouldOfferApplePay: Whether or not to show Apple Pay as a payment option.
        init(
            intent: Intent,
            configuration: PaymentSheet.Configuration,
            selectionOnly: Bool,
            shouldOfferApplePay: Bool
        ) {
            self.intent = intent
            self.configuration = configuration
            self.selectionOnly = selectionOnly
            self.shouldOfferApplePay = shouldOfferApplePay
        }
    }

    private(set) var linkAccount: PaymentSheetLinkAccount?

    private var context: Context

    weak var payWithLinkDelegate: PayWithLinkViewControllerDelegate?

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
        selectionOnly: Bool,
        shouldOfferApplePay: Bool = false
    ) {
        self.init(
            linkAccount: linkAccount,
            context: Context(
                intent: intent,
                configuration: configuration,
                selectionOnly: selectionOnly,
                shouldOfferApplePay: shouldOfferApplePay
            )
        )
    }

    private init(
        linkAccount: PaymentSheetLinkAccount?,
        context: Context
    ) {
        // TODO(porter): Hack, don't use payment sheet appearance in Link
        ElementsUITheme.current = ElementsUITheme.default
        self.linkAccount = linkAccount
        self.context = context
        super.init(nibName: nil, bundle: nil)

        PaymentSheet.supportedLinkPaymentMethods = linkAccount?.supportedPaymentMethodTypes ?? []

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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // TODO(porter): Hack, set appearance to payment sheet theme on dismiss
        ElementsUITheme.current = context.configuration.appearance.asElementsTheme
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
            loadAndPresentWallet()
        }
    }

}

private extension PayWithLinkViewController {

    func loadAndPresentWallet() {
        setRootViewController(LoaderViewController())

        guard let linkAccount = linkAccount else {
            assertionFailure("No link account is set")
            return
        }

        linkAccount.listPaymentDetails { (paymentDetails, error) in
            if let error = error {
                self.payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, result: PaymentSheetResult.failed(error: error))
                return
            }
            
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
        
        if context.selectionOnly {
            payWithLinkDelegate?.payWithLinkViewControllerDidSelectPaymentOption(self,
                                                                                 paymentOption: PaymentOption.link(account: linkAccount,
                                                                                                                         option: .withPaymentDetails(paymentDetails: paymentDetails)))
            completion(.completed)
        } else {
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
    }

    func confirmWithApplePay() {
        if context.selectionOnly {
            payWithLinkDelegate?.payWithLinkViewControllerDidSelectPaymentOption(self, paymentOption: .applePay)
        } else {
            payWithLinkDelegate?.payWithLinkViewControllerDidShouldConfirm(
                self,
                intent: context.intent,
                with: .applePay
            ) { [weak self] result in
                if case .canceled = result {
                    // no-op -- we don't dismiss/finish for canceled ApplePay interactions
                    return
                } else {
                    self?.finish(withResult: result)
                }
            }
        }
    }

    func cancel() {
        // TODO(porter): Hack, set appearance to payment sheet theme on dismiss
        ElementsUITheme.current = context.configuration.appearance.asElementsTheme
        payWithLinkDelegate?.payWithLinkViewControllerDidCancel(self)
    }

    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount) {
        self.linkAccount = linkAccount
        PaymentSheet.supportedLinkPaymentMethods = linkAccount.supportedPaymentMethodTypes
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
        context.lastAddedPaymentDetails = nil
        payWithLinkDelegate?.payWithLinkViewControllerDidUpdateLinkAccount(self, linkAccount: linkAccount)
        updateUI()
    }

}

