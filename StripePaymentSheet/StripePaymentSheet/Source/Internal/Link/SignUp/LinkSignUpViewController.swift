//
//  LinkSignUpViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/9/25.
//

import SafariServices
import UIKit

@_spi(STP) import StripeCore
@_exported @_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol LinkSignUpViewControllerDelegate: AnyObject {
    func signUpController(
        _ controller: LinkSignUpViewController,
        didCompleteSignUpWith linkAccount: PaymentSheetLinkAccount
    )
    func signUpController(
        _ controller: LinkSignUpViewController,
        didFailWithError error: Error
    )
    func signUpControllerDidCancel(_ controller: LinkSignUpViewController)
    func signUpControllerDidEncounterAttestationError(_ controller: LinkSignUpViewController)
}

/// For internal SDK use only
@objc(STP_Internal_LinkSignUpViewController)
final class LinkSignUpViewController: UIViewController {

    weak var delegate: LinkSignUpViewControllerDelegate?

    private let viewModel: LinkSignUpViewModel
    private let defaultBillingDetails: PaymentSheet.BillingDetails?
    private let theme = LinkUI.appearance.asElementsTheme

    private lazy var selectionBehavior: SelectionBehavior = {
        // This is lazily computed so that the iOS 26 style can be applied to LinkUI.
        SelectionBehavior.highlightBorder(configuration: LinkUI.highlightBorderConfiguration)
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = STPLocalizedString(
            "Fast, secure checkout",
            "Title for the Link signup screen"
        )
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .body)
        label.textColor = .linkTextSecondary
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = STPLocalizedString(
            "Pay faster everywhere Link is accepted.",
            "Subtitle for the Link signup screen"
        )
        return label
    }()

    private lazy var emailElement = {
        let element = LinkEmailElement(defaultValue: viewModel.emailAddress, showLogo: false, theme: theme)
        element.indicatorTintColor = .linkIconBrand
        return element
    }()

    private lazy var phoneNumberElement = PhoneNumberElement(
        defaultCountryCode: defaultBillingDetails?.address.country,
        defaultPhoneNumber: defaultBillingDetails?.phone,
        theme: theme
    )

    private lazy var nameElement = TextFieldElement(
        configuration: TextFieldElement.NameConfiguration(
            type: .full,
            defaultValue: viewModel.legalName
        ),
        theme: theme
    )

    private lazy var emailSection = SectionElement(
        elements: [emailElement],
        selectionBehavior: selectionBehavior,
        theme: theme
    )

    private lazy var phoneNumberSection = SectionElement(
        elements: [phoneNumberElement],
        selectionBehavior: selectionBehavior,
        theme: theme
    )

    private lazy var nameSection = SectionElement(
        elements: [nameElement],
        selectionBehavior: selectionBehavior,
        theme: theme
    )

    private lazy var legalTermsView: LinkLegalTermsView = {
        let legalTermsView = LinkLegalTermsView(textAlignment: .center, isStandalone: true)
        legalTermsView.tintColor = .linkTextBrand
        legalTermsView.delegate = self
        return legalTermsView
    }()

    private lazy var emailSuggestionLabel: TappableAttributedLabel = {
        let label = TappableAttributedLabel()
        label.font = LinkUI.font(forTextStyle: .caption)
        label.textColor = .linkTextSecondary
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: theme)
        label.isHidden = true
        return label
    }()

    private lazy var signUpButton: Button = {
        let button = Button(
            configuration: .linkPrimary(),
            title: viewModel.signUpButtonTitle
        )
        button.addTarget(self, action: #selector(didTapSignUpButton(_:)), for: .touchUpInside)
        button.adjustsFontForContentSizeCategory = true
        button.isEnabled = false
        if LinkUI.useLiquidGlass {
            button.ios26_applyCapsuleCornerConfiguration()
        }
        return button
    }()

    private(set) lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            emailSection.view,
            emailSuggestionLabel,
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount?,
        country: String? = nil,
        defaultBillingDetails: PaymentSheet.BillingDetails?
    ) {
        self.viewModel = LinkSignUpViewModel(
            accountService: accountService,
            linkAccount: linkAccount,
            legalName: defaultBillingDetails?.name,
            country: country ?? defaultBillingDetails?.address.country
        )
        self.defaultBillingDetails = defaultBillingDetails
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.tintColor = .linkTextPrimary

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: LinkUI.extraLargeContentSpacing),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

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

    func updateUI(animated: Bool = false) {
        if viewModel.isLookingUpLinkAccount {
            emailElement.startAnimating()
        } else {
            emailElement.stopAnimating()
        }

        // Email suggestion
        if let suggestedEmail = viewModel.suggestedEmail {
            updateEmailSuggestionLabel(with: suggestedEmail)
            stackView.setCustomSpacing(LinkUI.smallContentSpacing, after: emailSection.view)
            stackView.toggleArrangedSubview(
                emailSuggestionLabel,
                shouldShow: true,
                animated: animated
            )
        } else {
            stackView.setCustomSpacing(LinkUI.contentSpacing, after: emailSection.view)
            stackView.toggleArrangedSubview(
                emailSuggestionLabel,
                shouldShow: false,
                animated: animated
            )
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
        signUpButton.title = viewModel.signUpButtonTitle
        signUpButton.isEnabled = viewModel.shouldEnableSignUpButton
    }

    private func updateEmailSuggestionLabel(with suggestedEmail: String) {
        let baseText = STPLocalizedString(
            "Did you mean %@? %@.",
            "Text suggesting a corrected email address. First %@ will be replaced with the suggested email address, second %@ will be replaced with a tappable link."
        )
        let yesUpdateLocalizedText = STPLocalizedString(
            "Yes, update",
            "Text for a tappable link that will update the email field with a suggested email address."
        )
        let fullText = String(format: baseText, suggestedEmail, yesUpdateLocalizedText)

        emailSuggestionLabel.setText(
            fullText,
            baseFont: LinkUI.font(forTextStyle: .caption),
            baseColor: .linkTextSecondary,
            highlights: [
                TappableAttributedLabel.TappableHighlight(
                    text: yesUpdateLocalizedText,
                    font: LinkUI.font(forTextStyle: .caption),
                    color: .linkTextBrand,
                    action: { [weak self] in
                        self?.didTapYesUpdate()
                    }
                ),
            ]
        )
    }

    private func didTapYesUpdate() {
        guard let suggestedEmail = viewModel.suggestedEmail else {
            return
        }

        STPAnalyticsClient.sharedClient.logLinkEmailSuggestionAccepted()
        emailElement.emailAddressElement.setText(suggestedEmail)
        viewModel.emailAddress = suggestedEmail
    }

    @objc
    private func didTapSignUpButton(_ sender: Button) {
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
                self.delegate?.signUpController(self, didCompleteSignUpWith: account)
                STPAnalyticsClient.sharedClient.logLinkSignupComplete()
            case .failure(let error):
                self.delegate?.signUpController(self, didFailWithError: error)
                STPAnalyticsClient.sharedClient.logLinkSignupFailure(error: error)
            }

            self.signUpButton.isLoading = false
        }
    }

}

extension LinkSignUpViewController: LinkSignUpViewModelDelegate {
    func viewModelDidEncounterAttestationError(_ viewModel: LinkSignUpViewModel) {
        delegate?.signUpControllerDidEncounterAttestationError(self)
    }

    func viewModelDidChange(_ viewModel: LinkSignUpViewModel) {
        updateUI(animated: true)
    }

    func viewModel(
        _ viewModel: LinkSignUpViewModel,
        didLookupAccount linkAccount: PaymentSheetLinkAccount?
    ) {
        if let linkAccount {
            delegate?.signUpController(self, didCompleteSignUpWith: linkAccount)

            if !linkAccount.isRegistered {
                STPAnalyticsClient.sharedClient.logLinkSignupStart()
            }
        }
    }

}

extension LinkSignUpViewController: ElementDelegate {

    func didUpdate(element: Element) {
        // Forward delegate updates to the respective SectionElement
        if element === emailElement {
            emailSection.didUpdate(element: emailElement.emailAddressElement)
        } else if element === phoneNumberElement {
            phoneNumberSection.didUpdate(element: phoneNumberElement.lastUpdatedElement ?? element)
        } else if element === nameElement {
            nameSection.didUpdate(element: nameElement)
        }

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

extension LinkSignUpViewController: UITextViewDelegate {
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

extension LinkSignUpViewController: LinkLegalTermsViewDelegate {

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
