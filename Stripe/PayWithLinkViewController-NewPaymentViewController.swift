//
//  PayWithLinkViewController-NewPaymentViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

import SafariServices

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_NewPaymentViewController)
    final class NewPaymentViewController: BaseViewController {
        
        static let AddBankSuccessURLPathComponent: String = "success"
        static let AddBankCancelURLPathComponent: String = "cancel"
        
        let linkAccount: PaymentSheetLinkAccount
        let context: Context

        var safariViewController: SFSafariViewController? = nil

        
        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel()
        }()

        override var coordinator: PayWithLinkCoordinating? {
            didSet {
                footerView.coordinator = coordinator
            }
        }

        private lazy var scrollView: UIScrollView = {
            let scrollView = LinkKeyboardAvoidingScrollView()
            scrollView.keyboardDismissMode = .interactive
            return scrollView
        }()

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            // TODO(ramont): Localize
            label.text = "Add a payment method"
            return label
        }()

        private lazy var confirmButton: ConfirmButton = {
            let button = ConfirmButton(style: .stripe, callToAction: context.selectionOnly ? .add(paymentMethodType: addPaymentMethodVC.selectedPaymentMethodType) : context.intent.callToAction) { [weak self] in
                self?.confirm()
            }
            button.applyLinkTheme()
            return button
        }()

        private lazy var addPaymentMethodVC: AddPaymentMethodViewController = {
            var configuration = context.configuration
            configuration.linkPaymentMethodsOnly = true

            return AddPaymentMethodViewController(
                intent: context.intent,
                configuration: configuration,
                delegate: self
            )
        }()

        private lazy var footerView: LinkWalletFooterView = {
            let footerView = LinkWalletFooterView()
            footerView.linkAccount = linkAccount
            return footerView
        }()

        init(linkAccount: PaymentSheetLinkAccount, context: Context) {
            self.linkAccount = linkAccount
            self.context = context
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            self.view = scrollView
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            addChild(addPaymentMethodVC)

            view.backgroundColor = .linkBackground
            view.directionalLayoutMargins = LinkUI.contentMargins

            addPaymentMethodVC.view.backgroundColor = .clear
            errorLabel.isHidden = true

            let stackView = UIStackView(arrangedSubviews: [
                titleLabel,
                addPaymentMethodVC.view,
                errorLabel,
                confirmButton,
                footerView,
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.alignment = .center
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: titleLabel)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            scrollView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: LinkUI.contentMargins.top),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -LinkUI.contentMargins.bottom),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

                titleLabel.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                titleLabel.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),

                addPaymentMethodVC.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                addPaymentMethodVC.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

                confirmButton.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                confirmButton.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing),

                footerView.leadingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.leadingAnchor,
                    constant: LinkUI.contentMargins.leading),
                footerView.trailingAnchor.constraint(
                    equalTo: stackView.safeAreaLayoutGuide.trailingAnchor,
                    constant: -LinkUI.contentMargins.trailing)
            ])

            confirmButton.update(state: .disabled)
        }

        func confirm() {
            updateErrorLabel(for: nil)
            if addPaymentMethodVC.selectedPaymentMethodType == .linkInstantDebit {
                didSelectAddBankAccount(addPaymentMethodVC)
                return
            }
            
            guard let newPaymentOption = addPaymentMethodVC.paymentOption,
                  case .new(let confirmParams) = newPaymentOption else {
                assertionFailure()
                return
            }
            
            confirmButton.update(state: .processing)

            linkAccount.createPaymentDetails(with: confirmParams.paymentMethodParams) { [weak self] paymentDetails, error in
                guard let self = self else {
                    return
                }
                if let paymentDetails = paymentDetails {
                    
                    if case .card(let card) = paymentDetails.details {
                        card.cvc = confirmParams.paymentMethodParams.card?.cvc
                    }
                    
                    self.coordinator?.confirm(with: self.linkAccount,
                                              paymentDetails: paymentDetails,
                                              completion: { [weak self] result in
                        let state: ConfirmButton.Status
                        
                        switch result {
                        case .completed:
                            state = .succeeded
                        case .canceled:
                            state = .enabled
                        case .failed(let error):
                            state = .enabled
                            self?.updateErrorLabel(for: error)
                        }
                        
                        self?.confirmButton.update(state: state, animated: true) {
                            if state == .succeeded {
                                self?.coordinator?.finish(withResult: result)
                            }
                        }
                    })
                    
                } else {
                    self.confirmButton.update(state: .enabled, animated: true)
                    self.updateErrorLabel(for: error ?? NSError.stp_genericFailedToParseResponseError())
                }
            }
        }
        
        func didSelectAddBankAccount(_ viewController: AddPaymentMethodViewController) {
            guard let returnURLString = context.configuration.returnURL,
                  let returnURL = URL(string: returnURLString) else {
                assertionFailure()
                return
            }

            confirmButton.update(state: .processing)
            let successURL = returnURL.appendingPathComponent(Self.AddBankSuccessURLPathComponent).absoluteString
            let cancelURL = returnURL.appendingPathComponent(Self.AddBankCancelURLPathComponent).absoluteString
            linkAccount.createlinkAccountSession(successURL: successURL, cancelURL: cancelURL) { [weak self] linkAccountSession, createError in
                guard let self = self else {
                    return
                }
                if let linkAccountSession = linkAccountSession {
                    self.linkAccount.attachAsAccountHolder(to: linkAccountSession.clientSecret) { [weak self] attachResponse, attachError in
                        guard let self = self else {
                            return
                        }
                        if let attachResponse = attachResponse {
                            if let successURL = URL(string: successURL) {
                                STPURLCallbackHandler.shared().register(self, for: successURL)
                            }
                            if let cancelURL = URL(string: cancelURL) {
                                STPURLCallbackHandler.shared().register(self, for: cancelURL)
                            }
                            let safariViewController = SFSafariViewController(url: attachResponse.authorizationURL)
                            safariViewController.modalPresentationStyle = .overFullScreen
                            safariViewController.dismissButtonStyle = .close
                            
                            safariViewController.delegate = self
                            self.safariViewController = safariViewController
                            self.present(safariViewController, animated: true)
                        } else {
                            self.updateErrorLabel(for: attachError ?? NSError.stp_genericFailedToParseResponseError())
                        }
                    }
                } else {
                    self.updateErrorLabel(for: createError ?? NSError.stp_genericFailedToParseResponseError())
                }
            }
        }
        
        func updateErrorLabel(for error: Error?) {
            errorLabel.text = error?.nonGenericDescription
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.errorLabel.setHiddenIfNecessary(error == nil)
            }
        }

    }

}

extension PayWithLinkViewController.NewPaymentViewController: AddPaymentMethodViewControllerDelegate {

    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        if viewController.selectedPaymentMethodType == .linkInstantDebit {
            confirmButton.update(state: .enabled, style: .stripe, callToAction: .add(paymentMethodType: .linkInstantDebit))
        } else {
            confirmButton.update(state: viewController.paymentOption != nil ? .enabled : .disabled, callToAction: context.selectionOnly ? .add(paymentMethodType: viewController.selectedPaymentMethodType) : context.intent.callToAction)
        }
        updateErrorLabel(for: nil)
    }

    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
        return false
    }

}

// MARK: - SFSafariViewControllerDelegate
/// :nodoc:
extension PayWithLinkViewController.NewPaymentViewController: SFSafariViewControllerDelegate {
    @objc
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let safariViewController = safariViewController {
            self.safariViewController = nil
            confirmButton.update(state: .enabled)
            safariViewController.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - STPURLCallbackListener
/// :nodoc:
extension PayWithLinkViewController.NewPaymentViewController: STPURLCallbackListener {
    func handleURLCallback(_ url: URL) -> Bool {
        if let safariViewController = safariViewController {
            STPURLCallbackHandler.shared().unregisterListener(self)
            
            if url.lastPathComponent == Self.AddBankSuccessURLPathComponent,
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let linkedAccountID = components.queryItems?.first(where: { $0.name == "linked_account" })?.value {
                linkAccount.createPaymentDetails(linkedAccountId: linkedAccountID) { consumerDetails, error in
                    if error != nil {
                        self.updateErrorLabel(for: error)
                        self.confirmButton.update(state: .enabled)
                    } else {
                        // Store last added payment details so we can automatically select it on wallet
                        self.context.lastAddedPaymentDetails = consumerDetails
                        self.coordinator?.accountUpdated(self.linkAccount)
                        // Do not update confirmButton -- leave in processing while coordinator updates
                    }
                    self.safariViewController = nil
                    safariViewController.dismiss(animated: true, completion: nil)
                }
            } else {
                confirmButton.update(state: .enabled)
                if url.lastPathComponent == Self.AddBankSuccessURLPathComponent {
                    // something failed in parsing
                    self.updateErrorLabel(for: NSError.stp_genericFailedToParseResponseError())
                }
                self.safariViewController = nil
                safariViewController.dismiss(animated: true, completion: nil)
            }
            
            return true
        } else {
            return false
        }
    }
    
    
}
