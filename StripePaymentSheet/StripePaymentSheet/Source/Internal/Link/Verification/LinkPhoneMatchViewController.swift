// Copyright © 2026 Stripe, Inc. All rights reserved.

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class LinkPhoneMatchViewController: UIViewController, ElementDelegate {
    let phoneNumberElement: PhoneNumberElement
    private let phoneSection: SectionElement
    private let coordinator: LinkAuthFlowCoordinator
    private let hint: String
    private let errorLabel = UILabel()
    private let submitButton = Button(configuration: .linkPrimary(), title: String.Localized.continue)

    init(account: PaymentSheetLinkAccount, coordinator: LinkAuthFlowCoordinator, appearance: LinkAppearance?) {
        self.coordinator = coordinator
        phoneNumberElement = PhoneNumberElement(
            defaultCountryCode: account.currentSession?.phoneNumberCountry ?? account.authCountryCode ?? "US",
            theme: LinkUI.appearance.asElementsTheme
        )
        phoneSection = SectionElement(
            elements: [phoneNumberElement],
            theme: LinkUI.appearance.asElementsTheme
        )
        let lastTwo = String((account.currentSession?.redactedPhoneNumber ?? "").suffix(2))
        if lastTwo.count == 2, lastTwo.allSatisfy(\.isNumber) {
            hint = String(
                format: STPLocalizedString(
                    "Before we can send a code to your email, we need to verify additional information about you. Please enter your phone number ending in ••%@.",
                    "Phone-match instruction before Link email OTP. Placeholder is the last two phone digits."
                ),
                lastTwo
            )
        } else {
            hint = STPLocalizedString(
                "Before we can send a code to your email, we need to verify additional information about you. Please enter your phone number.",
                "Phone-match instruction before Link email OTP."
            )
        }
        super.init(nibName: nil, bundle: nil)
        phoneNumberElement.delegate = self
        if let primary = appearance?.colors?.primary {
            submitButton.configuration.backgroundColor = primary
            submitButton.configuration.disabledBackgroundColor = primary
        }
        if let contentOnPrimary = appearance?.colors?.contentOnPrimary {
            submitButton.configuration.foregroundColor = contentOnPrimary
        }
        if let cornerRadius = appearance?.primaryButton.cornerRadius {
            submitButton.configuration.cornerRadius = cornerRadius
        }
        submitButton.adjustsFontForContentSizeCategory = true
        if LinkUI.useLiquidGlass {
            submitButton.ios26_applyCapsuleCornerConfiguration()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.directionalLayoutMargins = .insets(amount: LinkVerificationView.Constants.edgeMargin)
        let title = label(
            STPLocalizedString(
                "Verify your phone number",
                "Heading for the Link phone-match screen."
            ),
            style: .title
        )
        let description = label(hint, style: .body)
        description.textColor = .linkTextSecondary
        errorLabel.font = LinkUI.font(forTextStyle: .detail)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.adjustsFontForContentSizeCategory = true
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        let stack = UIStackView(
            arrangedSubviews: [
                title,
                description,
                phoneSection.view,
                errorLabel,
                submitButton,
            ]
        )
        stack.axis = .vertical
        stack.spacing = LinkUI.contentSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
        render()
    }

    func render() {
        loadViewIfNeeded()
        errorLabel.text = coordinator.errorMessage
        errorLabel.isHidden = coordinator.errorMessage == nil
        submitButton.isLoading = coordinator.isLoading
        submitButton.isEnabled = phoneNumberElement.validationState.isValid && phoneNumberElement.phoneNumber != nil && !coordinator.isLoading
        phoneSection.view.isUserInteractionEnabled = !coordinator.isLoading
    }

    func focusPhone() { _ = phoneNumberElement.beginEditing() }

    @objc private func submit() {
        guard phoneNumberElement.validationState.isValid, let phone = phoneNumberElement.phoneNumber?.string(as: .e164) else { return }
        coordinator.submitPhoneNumber(phone)
    }

    func didUpdate(element: Element) {
        phoneSection.didUpdate(element: phoneNumberElement.lastUpdatedElement ?? element)
        render()
    }

    func continueToNextField(element: Element) { submit() }

    private func label(_ text: String, style: LinkUI.TextStyle) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = LinkUI.font(forTextStyle: style)
        label.textColor = .linkTextPrimary
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}
