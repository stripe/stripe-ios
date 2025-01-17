//
//  LinkInlineSignupView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SafariServices
@_spi(STP) import StripeUICore
import UIKit

protocol LinkInlineSignupViewDelegate: AnyObject {
    func inlineSignupViewDidUpdate(_ view: LinkInlineSignupView)
}

/// For internal SDK use only
@objc(STP_Internal_LinkInlineSignupView)
final class LinkInlineSignupView: UIView {

    weak var delegate: LinkInlineSignupViewDelegate?

    let viewModel: LinkInlineSignupViewModel

    private var theme: ElementsAppearance {
        return viewModel.configuration.appearance.asElementsTheme
    }

    let borderColor: UIColor

    private(set) lazy var checkboxElement = CheckboxElement(
        merchantName: viewModel.configuration.merchantDisplayName,
        appearance: viewModel.configuration.appearance,
        borderColor: borderColor
    )

    private(set) lazy var emailElement: LinkEmailElement = {
        let element = LinkEmailElement(defaultValue: viewModel.emailAddress,
                                       isOptional: viewModel.isEmailOptional,
                                       showLogo: viewModel.mode != .textFieldsOnlyPhoneFirst,
                                       theme: theme)
        element.indicatorTintColor = theme.colors.primary
        return element
    }()

    private(set) lazy var nameElement: TextFieldElement = {
        let configuration = TextFieldElement.NameConfiguration(type: .full, defaultValue: viewModel.legalName)
        return TextFieldElement(configuration: configuration, theme: theme)
    }()

    private(set) lazy var phoneNumberElement: PhoneNumberElement = {
        // Don't allow a default phone number in textFieldsOnly mode.
        // Otherwise, we'd imply consumer consent when it hasn't occurred.
        switch viewModel.mode {
        case .checkbox:
            return PhoneNumberElement(
                defaultCountryCode: viewModel.configuration.defaultBillingDetails.address.country,
                defaultPhoneNumber: viewModel.configuration.defaultBillingDetails.phone,
                theme: theme
        )
        case .textFieldsOnlyEmailFirst:
            return PhoneNumberElement(isOptional: viewModel.isPhoneNumberOptional, theme: theme)
        case .textFieldsOnlyPhoneFirst:
            return PhoneNumberElement(isOptional: viewModel.isPhoneNumberOptional, infoView: LinkMoreInfoView(), theme: theme)
        }
    }()

    // MARK: Sections

    private lazy var emailSection: Element = {
        return emailElement
    }()

    private lazy var nameSection: Element = {
        return nameElement
    }()

    private lazy var phoneNumberSection: Element = {
        return phoneNumberElement
    }()

    private(set) lazy var legalTermsElement: StaticElement = {
        let legalView = LinkLegalTermsView(textAlignment: .left,
                                           mode: viewModel.mode,
                                           delegate: self)
        legalView.font = theme.fonts.caption
        legalView.textColor = theme.colors.secondaryText
        legalView.tintColor = theme.colors.primary

        return StaticElement(
            view: legalView
        )
    }()

    private lazy var combinedEmailNameSection: Element = {
        return SectionElement(elements: [emailSection, phoneNumberSection, nameElement], theme: theme)
    }()

    private lazy var formElement: FormElement = {
        var elements: [Element] = []
        if viewModel.mode == .textFieldsOnlyPhoneFirst {
            elements.insert(contentsOf: [phoneNumberSection, emailSection, nameSection], at: 0)
        } else if viewModel.mode == .textFieldsOnlyEmailFirst {
            elements.insert(contentsOf: [emailSection, phoneNumberSection, nameSection], at: 0)
        } else if viewModel.mode == .checkbox {
            elements.insert(contentsOf: [checkboxElement], at: 0)
            elements.insert(contentsOf: [combinedEmailNameSection], at: 1)
        }

        let style: FormElement.Style = viewModel.showCheckbox ? .plain : .bordered
        let formElement = FormElement(elements: elements, style: style, theme: theme)
        let containerFormElement = FormElement(elements: [formElement, legalTermsElement], theme: theme, customSpacing: [(formElement, ElementsUI.formSpacing - 4.0)])
        return containerFormElement
    }()

    init(viewModel: LinkInlineSignupViewModel) {
        self.viewModel = viewModel

        if viewModel.configuration.appearance.colors.componentBorder.rgba.alpha != 0 {
            // Link border color should match other component borders
            borderColor = viewModel.configuration.appearance.colors.componentBorder
        } else {
            // If the borders are hidden, use a color that contrasts with the background color.
            let backgroundColor = viewModel.configuration.appearance.colors.background
            borderColor = UIColor(dynamicProvider: { traitCollection in
                return backgroundColor.resolvedColor(with: traitCollection).contrastingColor.withAlphaComponent(0.2)
            })
        }
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
        directionalLayoutMargins = .insets(amount: viewModel.layoutInsets)

        formElement.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(formElement.view)

        NSLayoutConstraint.activate([
            formElement.view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            formElement.view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            formElement.view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            formElement.view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])

        updateAppearance()
    }

    func setupDefaults() {
        viewModel.phoneNumber = phoneNumberElement.phoneNumber
        if let phoneNumber = viewModel.phoneNumber,
           !phoneNumber.isEmpty {
            viewModel.phoneNumberWasPrefilled = true
        }
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
        if viewModel.mode == .checkbox {
            formElement.toggleChild(combinedEmailNameSection, show: viewModel.shouldShowEmailField, animated: animated)
        }
        formElement.toggleChild(emailSection, show: viewModel.shouldShowEmailField, animated: animated)
        formElement.toggleChild(phoneNumberSection, show: viewModel.shouldShowPhoneField, animated: animated)
        formElement.toggleChild(nameSection, show: viewModel.shouldShowNameField, animated: animated)
        formElement.toggleChild(legalTermsElement, show: viewModel.shouldShowLegalTerms, animated: animated)

        switch viewModel.mode {
        case .checkbox:
            // 2-way binding
            checkboxElement.isChecked = viewModel.saveCheckboxChecked
        case .textFieldsOnlyEmailFirst, .textFieldsOnlyPhoneFirst:
            // assume checkbox is checked in text field only mode
            viewModel.saveCheckboxChecked = true
        }
    }

    private func updateAppearance() {
        backgroundColor = viewModel.configuration.appearance.colors.background
        layer.cornerRadius = viewModel.configuration.appearance.cornerRadius
        // If the borders are hidden give Link a default 1.0 border that contrasts with the background color
        if viewModel.configuration.appearance.borderWidth == 0.0 ||
            viewModel.configuration.appearance.colors.componentBorder.rgba.alpha == 0.0 {
            layer.borderWidth = 1.0
            layer.borderColor = borderColor.cgColor
        }
    }

    #if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }
    #endif

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

        #if !canImport(CompositorServices)
        safariVC.dismissButtonStyle = .close
        safariVC.preferredControlTintColor = window?.tintColor ?? viewModel.configuration.appearance.colors.primary
        #endif
        safariVC.modalPresentationStyle = .overFullScreen

        guard let topController = window?.findTopMostPresentedViewController() else {
            return false
        }

        topController.present(safariVC, animated: true)
        return true
    }

}

extension LinkInlineSignupView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            switch event {
            case .shouldDisableUserInteraction:
                self.checkboxElement.setUserInteraction(isUserInteractionEnabled: false)
            case .shouldEnableUserInteraction:
                self.checkboxElement.setUserInteraction(isUserInteractionEnabled: true)
            default:
                break
            }
        }
    }
}
