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
        private let context: Context

        private let viewModel: SignUpViewModel

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.textColor = .linkPrimaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = STPLocalizedString(
                "Secure 1⁠-⁠click checkout",
                "Title for the Link signup screen"
            )
            return label
        }()

        private lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkSecondaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = String.Localized.pay_faster_at_$merchant_and_thousands_of_merchants(
                merchantDisplayName: context.configuration.merchantDisplayName
            )
            return label
        }()

        private lazy var emailElement: LinkEmailElement = {
            return LinkEmailElement(defaultValue: viewModel.emailAddress)
        }()

        private lazy var phoneNumberElement = PhoneNumberElement(
            defaultValue: context.configuration.defaultBillingDetails.phone,
            defaultCountry: context.configuration.defaultBillingDetails.address.country
        )

        private lazy var phoneNumberSection = SectionElement(elements: [phoneNumberElement])

        private lazy var nameElement = TextFieldElement(
            configuration: TextFieldElement.NameConfiguration(
                type: .full,
                defaultValue: viewModel.legalName
            )
        )

        private lazy var nameSection = SectionElement(elements: [nameElement])

        private lazy var legalTermsView: LinkLegalTermsView = {
            let legalTermsView = LinkLegalTermsView(textAlignment: .center)
            legalTermsView.tintColor = .linkBrandDark
            legalTermsView.delegate = self
            return legalTermsView
        }()

        private lazy var errorLabel: UILabel = {
            let label = ElementsUI.makeErrorLabel()
            label.isHidden = true
            return label
        }()

        private lazy var signUpButton: Button = {
            let button = Button(
                configuration: .linkPrimary(),
                title: STPLocalizedString(
                    "Join Link",
                    "Title for a button that when tapped creates a Link account for the user."
                )
            )
            button.addTarget(self, action: #selector(didTapSignUpButton(_:)), for: .touchUpInside)
            button.adjustsFontForContentSizeCategory = true
            button.isEnabled = false
            return button
        }()

        private lazy var stackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [
                titleLabel,
                subtitleLabel,
                emailElement.view,
                phoneNumberSection.view,
                nameSection.view,
                legalTermsView,
                errorLabel,
                signUpButton
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.smallContentSpacing, after: titleLabel)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: subtitleLabel)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: legalTermsView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins

            return stackView
        }()

        init(
            linkAccount: PaymentSheetLinkAccount?,
            context: Context
        ) {
            self.context = context
            self.viewModel = SignUpViewModel(
                configuration: context.configuration,
                accountService: LinkAccountService(apiClient: context.configuration.apiClient),
                linkAccount: linkAccount,
                country: context.intent.countryCode
            )
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            let scrollView = LinkKeyboardAvoidingScrollView()
            scrollView.keyboardDismissMode = .interactive
            scrollView.addSubview(stackView)

            contentView.addAndPinSubview(scrollView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])

            setupBindings()
            updateUI()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            STPAnalyticsClient.sharedClient.logLinkSignupFlowPresented()
        }

        private func setupBindings() {
            // Logic for determining the default phone number currently lives
            // in the UI layer. In the absence of two-way data binding, we will
            // need to sync up the view model with the view here.
            viewModel.phoneNumber = phoneNumberElement.phoneNumber

            viewModel.delegate = self
            emailElement.delegate = self
            phoneNumberElement.delegate = self
            nameElement.delegate = self
        }

        private func updateUI(animated: Bool = false) {
            if viewModel.isLookingUpLinkAccount {
                emailElement.startAnimating()
            } else {
                emailElement.stopAnimating()
            }

            // Phone number
            stackView.toggleArrangedSubview(
                phoneNumberSection.view,
                shouldShow: viewModel.shouldShowPhoneNumberField,
                animated: animated
            )

            // Name
            stackView.toggleArrangedSubview(
                nameSection.view,
                shouldShow: viewModel.shouldShowNameField,
                animated: animated
            )

            // Legal terms
            stackView.toggleArrangedSubview(
                legalTermsView,
                shouldShow: viewModel.shouldShowLegalTerms,
                animated: animated
            )

            // Error message
            errorLabel.text = viewModel.errorMessage
            stackView.toggleArrangedSubview(
                errorLabel,
                shouldShow: viewModel.errorMessage != nil,
                animated: animated
            )

            // Signup button
            stackView.toggleArrangedSubview(
                signUpButton,
                shouldShow: viewModel.shouldShowSignUpButton,
                animated: animated
            )

            signUpButton.isEnabled = viewModel.shouldEnableSignUpButton
        }

        @objc
        func didTapSignUpButton(_ sender: Button) {
            signUpButton.isLoading = true

            viewModel.signUp { [weak self] result in
                switch result {
                case .success(let account):
                    self?.coordinator?.accountUpdated(account)
                    STPAnalyticsClient.sharedClient.logLinkSignupComplete()
                case .failure(_):
                    STPAnalyticsClient.sharedClient.logLinkSignupFailure()
                }

                self?.signUpButton.isLoading = false
            }
        }

    }

}

extension PayWithLinkViewController.SignUpViewController: PayWithLinkSignUpViewModelDelegate {

    func viewModelDidChange(_ viewModel: PayWithLinkViewController.SignUpViewModel) {
        updateUI(animated: true)
    }

    func viewModel(
        _ viewModel: PayWithLinkViewController.SignUpViewModel,
        didLookupAccount linkAccount: PaymentSheetLinkAccount?
    ) {
        if let linkAccount = linkAccount {
            coordinator?.accountUpdated(linkAccount)

            if !linkAccount.isRegistered {
                STPAnalyticsClient.sharedClient.logLinkSignupStart()
            }
        }
    }

}

extension PayWithLinkViewController.SignUpViewController: ElementDelegate {

    func didUpdate(element: Element) {
        switch emailElement.validationState {
        case .valid:
            viewModel.emailAddress = emailElement.emailAddressString
        case .invalid(_):
            viewModel.emailAddress = nil
        }

        viewModel.phoneNumber = phoneNumberElement.phoneNumber

        switch nameElement.validationState {
        case .valid:
            viewModel.legalName = nameElement.text
        case .invalid(_):
            viewModel.legalName = nil
        }
    }

    func continueToNextField(element: Element) {
        // No-op
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
