//
//  PayWithLinViewController-SignUpViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import SafariServices

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PayWithLinkSignUpViewController)
    final class SignUpViewController: BaseViewController {
        let context: Context

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            // TODO(ramont): Localize
            label.text = "Secure 1⁠-⁠click checkout"
            return label
        }()

        private let phoneNumberElement = PhoneNumberElement()

        lazy var phoneElement: PaymentMethodElement = {
            let wrapper: PaymentMethodElementWrapper<PhoneNumberElement> = PaymentMethodElementWrapper(phoneNumberElement) { phoneNumberElement, params in
                params.paymentMethodParams.nonnil_billingDetails.phone = phoneNumberElement.phoneNumberText
                return params
            }
            return FormElement(elements: [wrapper], style: .bordered)
        }()

        private lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = CompatibleColor.secondaryLabel
            // TODO(ramont): Localize
            label.text = String(
                format: "Pay faster at %@ and thousands of merchants.",
                context.configuration.merchantDisplayName
            )
            return label
        }()

        private lazy var emailElement: LinkEmailElement = {
            return LinkEmailElement(defaultValue: linkAccount?.email)
        }()
        
        private lazy var errorLabel: UILabel = {
            return ElementsUI.makeErrorLabel()
        }()

        private(set) var linkAccount: PaymentSheetLinkAccount? {
            didSet {
                phoneNumberElement.resetNumber()
                phoneElement.view.isHidden = linkAccount == nil
                signUpButton.isHidden = linkAccount == nil
                legalTermsView.isHidden = linkAccount == nil
            }
        }

        private lazy var legalTermsView = LinkLegalTermsView(textAlignment: .center)

        private lazy var signUpButton: Button = {
            // TODO(ramont): Localize
            let button = Button(configuration: .linkPrimary(), title: "Join Link")
            button.addTarget(self, action: #selector(didTapSignUpButton(_:)), for: .touchUpInside)
            button.adjustsFontForContentSizeCategory = true
            button.isEnabled = false
            return button
        }()

        private lazy var accountService = LinkAccountService(apiClient: context.configuration.apiClient)

        private let accountLookupDebouncer = OperationDebouncer(debounceTime: .milliseconds(500))

        init(
            linkAccount: PaymentSheetLinkAccount?,
            context: Context
        ) {
            self.linkAccount = linkAccount
            self.context = context
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            emailElement.delegate = self
            phoneElement.delegate = self
            legalTermsView.delegate = self
            errorLabel.isHidden = true
            
            let stack = UIStackView(arrangedSubviews: [
                titleLabel,
                subtitleLabel,
                emailElement.view,
                phoneElement.view,
                legalTermsView,
                errorLabel,
                signUpButton
            ])
            stack.axis = .vertical
            stack.spacing = LinkUI.contentSpacing
            stack.setCustomSpacing(LinkUI.smallContentSpacing, after: titleLabel)
            stack.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: subtitleLabel)
            stack.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: legalTermsView)
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.isLayoutMarginsRelativeArrangement = true
            stack.directionalLayoutMargins = LinkUI.contentMargins

            let scrollView = LinkKeyboardAvoidingScrollView()
            scrollView.alwaysBounceVertical = true
            scrollView.keyboardDismissMode = .interactive
            scrollView.addSubview(stack)

            view.addAndPinSubview(scrollView)

            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])

            phoneElement.view.isHidden = linkAccount == nil
            legalTermsView.isHidden = linkAccount == nil
            signUpButton.isHidden = linkAccount == nil
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            STPAnalyticsClient.sharedClient.logLinkSignupFlowPresented()
        }

        @objc func didTapSignUpButton(_ sender: Button) {
            updateErrorLabel(for: nil)
            
            guard let linkAccount = linkAccount else {
                assertionFailure()
                return
            }

            if let phoneNumber = phoneNumberElement.phoneNumber {
                sender.isLoading = true

                linkAccount.signUp(with: phoneNumber) { result in
                    switch result {
                    case .success():
                        self.coordinator?.accountUpdated(linkAccount)
                        STPAnalyticsClient.sharedClient.logLinkSignupComplete()
                    case .failure(let error):
                        sender.isLoading = false
                        self.updateErrorLabel(for: error)
                        STPAnalyticsClient.sharedClient.logLinkSignupFailure()
                    }
                }
            } else if let phoneNumberText = phoneNumberElement.phoneNumberText { // fall-back to raw string, let server validation fail
                sender.isLoading = true

                linkAccount.signUp(with: phoneNumberText, countryCode: nil) { result in
                    switch result {
                    case .success():
                        self.coordinator?.accountUpdated(linkAccount)
                    case .failure(let error):
                        sender.isLoading = false
                        self.updateErrorLabel(for: error)
                    }
                }
            } else {
                assertionFailure()
            }
        }

        func emailDidUpdate() {
            guard emailElement.emailAddressString != linkAccount?.email else {
                return
            }
            if let linkAccount = linkAccount,
               linkAccount.sessionState != .requiresSignUp {
                coordinator?.logout()
            }
            self.linkAccount = nil
            emailElement.stopAnimating()
            if case .valid = emailElement.validationState,
               let currentEmail = emailElement.emailAddressString {
                // Wait half a second before loading in case user edits
                accountLookupDebouncer.enqueue {
                    guard currentEmail == self.emailElement.emailAddressString else {
                        return // user typed something else
                    }
                    self.emailElement.startAnimating()
                    self.accountService.lookupAccount(withEmail: currentEmail) { [weak self] result in
                        self?.emailElement.stopAnimating()
                        switch result {
                        case .success(let linkAccount):
                            if let linkAccount = linkAccount {
                                self?.linkAccount = linkAccount
                                self?.coordinator?.accountUpdated(linkAccount)

                                if !linkAccount.isRegistered {
                                    STPAnalyticsClient.sharedClient.logLinkSignupStart()
                                }
                            }
                        case .failure(let error):
                            self?.updateErrorLabel(for: error)
                            break
                        }
                    }
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

extension PayWithLinkViewController.SignUpViewController: ElementDelegate {

    func didUpdate(element: Element) {
        updateErrorLabel(for: nil)
        if element is LinkEmailElement {
            emailDidUpdate()
        } else if let paymentMethodElement = element as? PaymentMethodElement {
            if let params = paymentMethodElement.updateParams(params: IntentConfirmParams(type: .link)),
               params.paymentMethodParams.billingDetails?.phone != nil {
                signUpButton.isEnabled = linkAccount?.email != nil
            } else {
                signUpButton.isEnabled = false
            }
        }

    }

    func didFinishEditing(element: Element) {
        if element is LinkEmailElement {
            emailDidUpdate()
        } else if let paymentMethodElement = element as? PaymentMethodElement {
            if let params = paymentMethodElement.updateParams(params: IntentConfirmParams(type: .link)),
               params.paymentMethodParams.billingDetails?.phone != nil {
                signUpButton.isEnabled = linkAccount?.email != nil
            } else {
                signUpButton.isEnabled = false
            }
        }
    }

}

extension PayWithLinkViewController.SignUpViewController: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if interaction == .invokeDefaultAction {
            let safariVC = SFSafariViewController(url: URL)
            present(safariVC, animated: true)
        }

        return false
    }

}

extension PayWithLinkViewController.SignUpViewController: LinkLegalTermsViewDelegate {

    func legalTermsView(_ legalTermsView: LinkLegalTermsView, didTapOnLinkWithURL url: URL) -> Bool {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .close
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
        return true
    }

}
