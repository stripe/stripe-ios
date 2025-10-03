//
//  PayWithLinkViewController-PhoneVerificationViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 10/2/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension PayWithLinkViewController {

    final class PhoneVerificationViewController: BaseViewController {

        private let linkAccount: PaymentSheetLinkAccount
        private let theme = LinkUI.appearance.asElementsTheme

        private lazy var headingLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = LinkUI.font(forTextStyle: .title)
            label.textColor = .linkTextPrimary
            label.text = STPLocalizedString(
                "Verify your phone number",
                "Heading for phone number verification screen"
            )
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private lazy var bodyLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkTextSecondary
            let format = STPLocalizedString(
                "Before we can send a code to your email, we need to verify additional information about you. Please enter your phone number ending in %@.",
                "Instructions for phone number verification"
            )
            let lastDigits = String(linkAccount.redactedPhoneNumber ?? "")
            label.text = String(format: format, lastDigits)
            label.adjustsFontForContentSizeCategory = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private lazy var phoneNumberElement: PhoneNumberElement = {
            let element = PhoneNumberElement(
                defaultCountryCode: linkAccount.currentSession?.phoneNumberCountry,
                theme: theme
            )
            element.delegate = self
            element.view.backgroundColor = .linkSurfaceSecondary
            element.view.layer.cornerRadius = LinkUI.cornerRadius
            element.view.layer.masksToBounds = true
            return element
        }()

        private lazy var errorLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .detail)
            label.textColor = .systemRed
            label.numberOfLines = 0
            label.textAlignment = .center
            label.isHidden = true
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private lazy var verifyButton: Button = {
            let button = Button(
                configuration: .linkPrimary(),
                title: STPLocalizedString(
                    "Verify",
                    "Button to verify phone number"
                )
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
            return button
        }()

        private lazy var backButton: Button = {
            let button = Button(
                configuration: .linkSecondary(),
                title: STPLocalizedString(
                    "Back",
                    "Button to go back to previous screen"
                )
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
            return button
        }()

        private lazy var stackView: UIStackView = {
            let formStackView = UIStackView(arrangedSubviews: [
                phoneNumberElement.view,
                errorLabel,
            ])
            formStackView.axis = .vertical
            formStackView.spacing = LinkUI.smallContentSpacing

            let buttonStackView = UIStackView(arrangedSubviews: [
                verifyButton,
                backButton,
            ])
            buttonStackView.axis = .vertical
            buttonStackView.spacing = LinkUI.smallContentSpacing

            let stackView = UIStackView(arrangedSubviews: [
                headingLabel,
                bodyLabel,
                formStackView,
                buttonStackView,
            ])
            stackView.axis = .vertical
            stackView.spacing = LinkUI.contentSpacing
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: bodyLabel)
            stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: formStackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0,
                leading: LinkUI.contentSpacing,
                bottom: 0,
                trailing: LinkUI.contentSpacing
            )
            stackView.isLayoutMarginsRelativeArrangement = true
            return stackView
        }()

        override var requiresFullScreen: Bool { true }

        override var preferredNavigationBarStyle: SheetNavigationBar.Style? {
            SheetNavigationBar.Style.close(showAdditionalButton: false)
        }

        init(linkAccount: PaymentSheetLinkAccount, context: Context) {
            self.linkAccount = linkAccount
            super.init(context: context)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            contentView.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: LinkUI.contentSpacing),
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

                verifyButton.heightAnchor.constraint(equalToConstant: LinkUI.primaryButtonHeight(margins: LinkUI.buttonMargins)),
                backButton.heightAnchor.constraint(equalToConstant: LinkUI.primaryButtonHeight(margins: LinkUI.buttonMargins)),
            ])

            updateUI()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            _ = phoneNumberElement.beginEditing()
        }

        @objc
        private func verifyButtonTapped() {
            guard let phoneNumber = phoneNumberElement.phoneNumber, phoneNumber.isComplete else {
                errorLabel.text = STPLocalizedString(
                    "Please enter a valid phone number.",
                    "Error message for invalid phone number"
                )
                errorLabel.isHidden = false
                return
            }

            errorLabel.isHidden = true
            verifyButton.isLoading = true
            view.isUserInteractionEnabled = false

            linkAccount.startVerification(
                factor: .email,
                accountPhoneNumber: phoneNumber.string(as: .e164)
            ) { [weak self] result in
                guard let self else { return }

                DispatchQueue.main.async {
                    self.verifyButton.isLoading = false
                    self.view.isUserInteractionEnabled = true

                    switch result {
                    case .success:
                        self.transitionToEmailVerification()
                    case .failure(let error):
                        self.errorLabel.text = LinkUtils.getLocalizedErrorMessage(from: error)
                        self.errorLabel.isHidden = false
                    }
                }
            }
        }

        @objc
        private func backButtonTapped() {
            _ = (coordinator as? PayWithLinkViewController)?.popContentViewController()
        }

        private func transitionToEmailVerification() {
            let emailVerificationVC = VerifyAccountViewController(
                linkAccount: linkAccount,
                context: context,
                initialVerificationFactor: .email
            )
            coordinator?.setViewControllers([emailVerificationVC])
        }

        private func updateUI() {
            let isValid = phoneNumberElement.phoneNumber?.isComplete ?? false
            verifyButton.isEnabled = isValid
        }
    }
}

extension PayWithLinkViewController.PhoneVerificationViewController: ElementDelegate {
    func didUpdate(element: Element) {
        updateUI()
    }

    func continueToNextField(element: Element) {
        verifyButtonTapped()
    }
}
