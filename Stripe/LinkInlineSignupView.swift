//
//  LinkInlineSignupView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import SafariServices
@_spi(STP) import StripeUICore

protocol LinkInlineSignupViewDelegate: AnyObject {
    func inlineSignupViewDidUpdate(_ view: LinkInlineSignupView)
}

/// For internal SDK use only
@objc(STP_Internal_LinkInlineSignupView)
final class LinkInlineSignupView: UIView {

    weak var delegate: LinkInlineSignupViewDelegate?

    let viewModel: LinkInlineSignupViewModel

    private var theme: ElementsUITheme {
        return viewModel.configuration.appearance.asElementsTheme
    }
    
    private(set) lazy var checkboxElement = CheckboxElement(
        merchantName: viewModel.configuration.merchantDisplayName,
        appearance: viewModel.configuration.appearance
    )

    private(set) lazy var emailElement : LinkEmailElement = {
        let element = LinkEmailElement(defaultValue: viewModel.emailAddress, theme: theme)
        element.indicatorTintColor = theme.colors.primary
        return element
    }()

    private(set) lazy var nameElement: TextFieldElement = {
        let configuration = TextFieldElement.NameConfiguration(type: .full, defaultValue: viewModel.legalName)
        return TextFieldElement(configuration: configuration, theme: theme)
    }()

    private(set) lazy var phoneNumberElement = PhoneNumberElement(
        defaultCountryCode: viewModel.configuration.defaultBillingDetails.address.country,
        defaultPhoneNumber: viewModel.configuration.defaultBillingDetails.phone, theme: theme
    )

    // MARK: Sections

    private lazy var emailSection = SectionElement(elements: [emailElement], theme: theme)

    private lazy var nameSection = SectionElement(elements: [nameElement], theme: theme)

    private lazy var phoneNumberSection = SectionElement(elements: [phoneNumberElement], theme: theme)

    private(set) lazy var legalTermsElement: StaticElement = {
        let legalView = LinkLegalTermsView(textAlignment: .left, delegate: self)
        legalView.font = theme.fonts.caption
        legalView.textColor = theme.colors.secondaryText
        legalView.tintColor = theme.colors.primary
        
        return StaticElement(
            view: legalView
        )
    }()

    private(set) lazy var moreInfoElement: StaticElement = {
        let infoView = LinkMoreInfoView(theme: theme)
        return StaticElement(view: infoView)
    }()

    private lazy var formElement = FormElement(elements: [
        checkboxElement,
        emailSection,
        phoneNumberSection,
        nameSection,
        legalTermsElement,
        moreInfoElement,
    ], theme: theme)

    init(viewModel: LinkInlineSignupViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        setupDefaults()
        setupBindings()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        clipsToBounds = true
        directionalLayoutMargins = .insets(amount: 16)

        formElement.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(formElement.view)

        NSLayoutConstraint.activate([
            formElement.view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            formElement.view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            formElement.view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            formElement.view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
        
        updateAppearance()
    }

    func setupDefaults() {
        viewModel.phoneNumber = phoneNumberElement.phoneNumber
    }

    func setupBindings() {
        viewModel.delegate = self
        checkboxElement.delegate = self
        formElement.delegate = self
    }

    func updateUI(animated: Bool = false) {
        if viewModel.isLookingUpLinkAccount {
            emailElement.startAnimating()
        } else {
            emailElement.stopAnimating()
        }

        formElement.toggleChild(emailSection, show: viewModel.shouldShowEmailField, animated: animated)
        formElement.toggleChild(phoneNumberSection, show: viewModel.shouldShowPhoneField, animated: animated)
        formElement.toggleChild(nameSection, show: viewModel.shouldShowNameField, animated: animated)
        formElement.toggleChild(legalTermsElement, show: viewModel.shouldShowLegalTerms, animated: animated)
        formElement.toggleChild(moreInfoElement, show: viewModel.shouldShowLegalTerms, animated: animated)

        // 2-way binding
        checkboxElement.isChecked = viewModel.saveCheckboxChecked
    }
    
    private func updateAppearance() {
        backgroundColor = viewModel.configuration.appearance.colors.background
        layer.cornerRadius = viewModel.configuration.appearance.cornerRadius
        // If the borders are hidden give Link a default 1.0 border that contrasts with the background color
        if viewModel.configuration.appearance.borderWidth == 0.0 ||
            viewModel.configuration.appearance.colors.componentBorder.rgba.alpha == 0.0 {
            layer.borderWidth = 1.0
            layer.borderColor = viewModel.configuration.appearance
                .colors.background.contrastingColor.withAlphaComponent(0.2).cgColor
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }

    private func focusOnEmptyRequiredField() {
        if viewModel.emailAddress == nil {
            emailElement.beginEditing()
        } else if viewModel.requiresNameCollection && !viewModel.legalNameProvided {
            nameElement.beginEditing()
        } else if viewModel.requiresPhoneNumberCollection && !viewModel.phoneNumberProvided {
            _ = phoneNumberElement.beginEditing()
        }
    }

}

extension LinkInlineSignupView: ElementDelegate {

    func didUpdate(element: Element) {
        if element === checkboxElement {
            viewModel.saveCheckboxChecked = checkboxElement.isChecked
            if checkboxElement.isChecked {
                focusOnEmptyRequiredField()
            } else {
                endEditing(true)
            }
        } else {
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
    }

    func continueToNextField(element: Element) {
        // No-op
    }

}

extension LinkInlineSignupView: LinkInlineSignupViewModelDelegate {

    func signupViewModelDidUpdate(_ viewModel: LinkInlineSignupViewModel) {
        updateUI(animated: true)
        delegate?.inlineSignupViewDidUpdate(self)
    }

}

extension LinkInlineSignupView: LinkLegalTermsViewDelegate {

    func legalTermsView(_ legalTermsView: LinkLegalTermsView, didTapOnLinkWithURL url: URL) -> Bool {
        let safariVC = SFSafariViewController(url: url)
        safariVC.dismissButtonStyle = .close
        safariVC.modalPresentationStyle = .overFullScreen

        guard let topController = window?.findTopMostPresentedViewController() else {
            return false
        }

        topController.present(safariVC, animated: true)
        return true
    }

}
