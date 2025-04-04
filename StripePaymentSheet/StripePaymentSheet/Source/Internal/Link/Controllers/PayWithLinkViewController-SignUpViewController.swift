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

        private let viewModel: SignUpViewModel

        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .title)
            label.textColor = .linkPrimaryText
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = STPLocalizedString(
                "Fast, secure, 1⁠-⁠click checkout",
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
            label.text = String.Localized.save_your_payment_information_with_link
            return label
        }()

        private lazy var emailElement = LinkEmailElement(defaultValue: viewModel.emailAddress, showLogo: false, theme: LinkUI.appearance.asElementsTheme)

        private lazy var phoneNumberElement = PhoneNumberElement(
            defaultCountryCode: context.configuration.defaultBillingDetails.address.country,
            defaultPhoneNumber: context.configuration.defaultBillingDetails.phone,
            theme: LinkUI.appearance.asElementsTheme
        )

        private lazy var nameElement = TextFieldElement(
            configuration: TextFieldElement.NameConfiguration(
                type: .full,
                defaultValue: viewModel.legalName
            ),
            theme: LinkUI.appearance.asElementsTheme
        )

        private lazy var emailSection = SectionElement(elements: [emailElement], theme: LinkUI.appearance.asElementsTheme)

        private lazy var phoneNumberSection = SectionElement(elements: [phoneNumberElement], theme: LinkUI.appearance.asElementsTheme)

        private lazy var nameSection = SectionElement(elements: [nameElement], theme: LinkUI.appearance.asElementsTheme)

        private lazy var legalTermsView: LinkLegalTermsView = {
            let legalTermsView = LinkLegalTermsView(textAlignment: .center, isStandalone: true)
            legalTermsView.tintColor = .linkBrandDark
            legalTermsView.delegate = self
            return legalTermsView
        }()

        private lazy var errorLabel: UILabel = {
            let label = ElementsUI.makeErrorLabel(theme: LinkUI.appearance.asElementsTheme)
            label.isHidden = true
            return label
        }()

        private lazy var signUpButton: Button = {
            let button = Button(
                configuration: .linkPrimary(),
                title: STPLocalizedString(
                    "Agree and continue",
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
                emailSection.view,
                phoneNumberSection.view,
                nameSection.view,
                legalTermsView,
                errorLabel,
                signUpButton,
            ])

            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.smallContentSpacing, after: titleLabel)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: subtitleLabel)
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: legalTermsView)
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = LinkUI.contentMargins

            return stackView
        }()

        init(
            linkAccount: PaymentSheetLinkAccount?,
            context: Context
        ) {
            self.viewModel = SignUpViewModel(
                configuration: context.configuration,
                accountService: LinkAccountService(apiClient: context.configuration.apiClient, elementsSession: context.elementsSession),
                linkAccount: linkAccount,
                country: context.elementsSession.countryCode
            )
            super.init(context: context)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            let scrollView = LinkKeyboardAvoidingScrollView(contentView: stackView)
            #if !os(visionOS)
            scrollView.keyboardDismissMode = .interactive
            #endif

            contentView.addAndPinSubview(scrollView)

            setupBindings()
            updateUI()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            STPAnalyticsClient.sharedClient.logLinkSignupFlowPresented()

            // If the email field is empty, select it
            if emailElement.emailAddressString?.isEmpty ?? false {
                emailElement.beginEditing()
            }
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
                guard let self else {
                    return
                }

                switch result {
                case .success(let account):
                    // We can't access the following fields used for signup via the consumer session,
                    // so we keep track of it on the client.
                    account.phoneNumberUsedInSignup = self.viewModel.phoneNumber?.string(as: .e164)
                    account.nameUsedInSignup = self.viewModel.legalName
                    self.coordinator?.accountUpdated(account)
                    STPAnalyticsClient.sharedClient.logLinkSignupComplete()
                case .failure(let error):
                    STPAnalyticsClient.sharedClient.logLinkSignupFailure(error: error)
                }

                self.signUpButton.isLoading = false
            }
        }

    }

}

extension PayWithLinkViewController.SignUpViewController: PayWithLinkSignUpViewModelDelegate {
    func viewModelDidEncounterAttestationError(_ viewModel: PayWithLinkViewController.SignUpViewModel) {
        self.coordinator?.bailToWebFlow()
    }

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
        case .invalid:
            viewModel.emailAddress = nil
        }

        viewModel.phoneNumber = phoneNumberElement.phoneNumber

        switch nameElement.validationState {
        case .valid:
            viewModel.legalName = nameElement.text
        case .invalid:
            viewModel.legalName = nil
        }
    }

    func continueToNextField(element: Element) {
        // No-op
    }

}

extension PayWithLinkViewController.SignUpViewController: UITextViewDelegate {

#if !os(visionOS)
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
#endif

}

extension PayWithLinkViewController.SignUpViewController: LinkLegalTermsViewDelegate {

    func legalTermsView(_ legalTermsView: LinkLegalTermsView, didTapOnLinkWithURL url: URL) -> Bool {
        let safariVC = SFSafariViewController(url: url)
        #if !os(visionOS)
        safariVC.dismissButtonStyle = .close
        #endif
        safariVC.modalPresentationStyle = .overFullScreen
        present(safariVC, animated: true)
        return true
    }

}
