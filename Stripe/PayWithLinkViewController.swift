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

protocol PayWithLinkViewControllerDelegate: AnyObject {
    func payWithLinkViewControllerDidShouldConfirm(
        _ payWithLinkViewController: PayWithLinkViewController,
        intent: Intent,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult) -> Void
    )

    func payWithLinkViewControllerDidUpdateLinkAccount(
        _ payWithLinkViewController: PayWithLinkViewController,
        linkAccount: PaymentSheetLinkAccount?
    )

    func payWithLinkViewControllerDidCancel(_ payWithLinkViewController: PayWithLinkViewController)

    func payWithLinkViewControllerDidFinish(
        _ payWithLinkViewController: PayWithLinkViewController,
        result: PaymentSheetResult
    )

    func payWithLinkViewControllerDidSelectPaymentOption(
        _ payWithLinkViewController: PayWithLinkViewController,
        paymentOption: PaymentOption
    )
}

protocol PayWithLinkCoordinating: AnyObject {
    func confirm(
        with linkAccount: PaymentSheetLinkAccount,
        paymentDetails: ConsumerPaymentDetails,
        completion: @escaping (PaymentSheetResult) -> Void
    )
    func confirmWithApplePay()
    func cancel()
    func accountUpdated(_ linkAccount: PaymentSheetLinkAccount)
    func finish(withResult result: PaymentSheetResult)
    func logout(cancel: Bool)
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
        let shouldFinishOnClose: Bool
        var lastAddedPaymentDetails: ConsumerPaymentDetails?

        /// Creates a new Context object.
        /// - Parameters:
        ///   - intent: Intent.
        ///   - configuration: PaymentSheet configuration.
        ///   - selectionOnly: :nodoc:
        ///   - shouldOfferApplePay: Whether or not to show Apple Pay as a payment option.
        ///   - shouldFinishOnClose: Whether or not Link should finish with `.canceled` result instead of returning to Payment Sheet when the close button is tapped.
        init(
            intent: Intent,
            configuration: PaymentSheet.Configuration,
            selectionOnly: Bool,
            shouldOfferApplePay: Bool,
            shouldFinishOnClose: Bool
        ) {
            self.intent = intent
            self.configuration = configuration
            self.selectionOnly = selectionOnly
            self.shouldOfferApplePay = shouldOfferApplePay
            self.shouldFinishOnClose = shouldFinishOnClose
        }
    }

    private(set) var linkAccount: PaymentSheetLinkAccount? {
        didSet {
            payWithLinkDelegate?.payWithLinkViewControllerDidUpdateLinkAccount(
                self,
                linkAccount: linkAccount
            )
        }
    }

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
        shouldOfferApplePay: Bool = false,
        shouldFinishOnClose: Bool = false
    ) {
        self.init(
            linkAccount: linkAccount,
            context: Context(
                intent: intent,
                configuration: configuration,
                selectionOnly: selectionOnly,
                shouldOfferApplePay: shouldOfferApplePay,
                shouldFinishOnClose: shouldFinishOnClose
            )
        )
    }

    private init(
        linkAccount: PaymentSheetLinkAccount?,
        context: Context
    ) {
        // TODO(porter): Hack, don't use payment sheet appearance in Link
        ElementsUITheme.current = LinkUI.appearance.asElementsTheme

        self.linkAccount = linkAccount
        self.context = context
        super.init(nibName: nil, bundle: nil)

        // Show loader
        setRootViewController(LoaderViewController(context: context), animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "Stripe.Link.PayWithLinkViewController"
        view.tintColor = .linkBrand

        // Hide the default navigation bar.
        setNavigationBarHidden(true, animated: false)

        if #available(iOS 13.0, *) {
            // Apply the preferred user interface style.
            context.configuration.style.configure(self)
        }

        updateSupportedPaymentMethods()
        updateUI()

        // The internal delegate of the interactive pop gesture disables
        // the gesture when the navigation bar is hidden. Use a custom delegate
        // to restore the functionality.
        interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // TODO(porter): Hack, set appearance to payment sheet theme on dismiss
        ElementsUITheme.current = context.configuration.appearance.asElementsTheme
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? BaseViewController {
            viewController.coordinator = self
            viewController.customNavigationBar.linkAccount = linkAccount
            viewController.customNavigationBar.showBackButton = viewControllers.count > 0
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
            setRootViewController(VerifyAccountViewController(linkAccount: linkAccount, context: context))
        case .verified:
            loadAndPresentWallet()
        }
    }

}

extension PayWithLinkViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }

}

// MARK: - Utils

private extension PayWithLinkViewController {

    func loadAndPresentWallet() {
        setRootViewController(LoaderViewController(context: context))

        guard let linkAccount = linkAccount else {
            assertionFailure("No link account is set")
            return
        }

        linkAccount.listPaymentDetails { result in
            switch result {
            case .success(let paymentDetails):
                if paymentDetails.isEmpty {
                    let addPaymentMethodVC = NewPaymentViewController(
                        linkAccount: linkAccount,
                        context: self.context,
                        isAddingFirstPaymentMethod: true
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
            case .failure(let error):
                self.payWithLinkDelegate?.payWithLinkViewControllerDidFinish(
                    self, result: PaymentSheetResult.failed(error: error)
                )
            }
        }
    }

    func updateSupportedPaymentMethods() {
        PaymentSheet.supportedLinkPaymentMethods =
            linkAccount?.supportedPaymentMethodTypes(for: context.intent) ?? []
    }

}

// MARK: - Navigation

private extension PayWithLinkViewController {

    var rootViewController: UIViewController? {
        return viewControllers.first
    }

    func setRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        if let viewController = viewController as? BaseViewController {
            viewController.coordinator = self
            viewController.customNavigationBar.linkAccount = linkAccount
            viewController.customNavigationBar.showBackButton = false
        }

        setViewControllers([viewController], animated: isShowingLoader ? false : animated)
    }

}

// MARK: - Coordinating

extension PayWithLinkViewController: PayWithLinkCoordinating {

    func confirm(with linkAccount: PaymentSheetLinkAccount, paymentDetails: ConsumerPaymentDetails, completion: @escaping (PaymentSheetResult) -> Void) {
        
        if context.selectionOnly {
            payWithLinkDelegate?.payWithLinkViewControllerDidSelectPaymentOption(
                self,
                paymentOption: .link(
                    account: linkAccount,
                    option: .withPaymentDetails(paymentDetails: paymentDetails)
                )
            )
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
        updateSupportedPaymentMethods()
        updateUI()
    }

    func finish(withResult result: PaymentSheetResult) {
        ElementsUITheme.current = context.configuration.appearance.asElementsTheme
        view.isUserInteractionEnabled = false
        payWithLinkDelegate?.payWithLinkViewControllerDidFinish(self, result: result)
    }

    func logout(cancel: Bool) {
        linkAccount?.logout()
        linkAccount = nil

        if cancel {
            self.cancel()
        } else {
            updateUI()
        }
    }

}
