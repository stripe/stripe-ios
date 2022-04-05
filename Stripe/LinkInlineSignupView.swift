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

    private(set) lazy var checkboxElement = CheckboxElement(merchantName: viewModel.merchantName,
                                                            appearance: viewModel.appearance)

    private(set) lazy var emailElement : LinkEmailElement = {
        let element = LinkEmailElement(defaultValue: viewModel.emailAddress)
        element.indicatorTintColor = ElementsUITheme.current.colors.primary
        return element
    }()

    private(set) lazy var phoneNumberElement = LinkPhoneNumberElement()
    
    private(set) lazy var errorElement = StaticElement(view: ElementsUI.makeErrorLabel())

    private(set) lazy var legalTermsElement: StaticElement = {
        let legalView = LinkLegalTermsView(textAlignment: .left, delegate: self)
        legalView.font = ElementsUITheme.current.fonts.caption
        legalView.textColor = ElementsUITheme.current.colors.secondaryText
        
        return StaticElement(
            view: legalView
        )
    }()

    private lazy var form = FormElement(elements: [
        checkboxElement,
        emailElement,
        phoneNumberElement,
        legalTermsElement,
        errorElement
    ])

    init(viewModel: LinkInlineSignupViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        setupBindings()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        clipsToBounds = true
        directionalLayoutMargins = .insets(amount: 16)

        form.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(form.view)

        checkboxElement.delegate = self

        NSLayoutConstraint.activate([
            form.view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            form.view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            form.view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            form.view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
    }

    func setupBindings() {
        viewModel.delegate = self
        emailElement.delegate = self
        phoneNumberElement.delegate = self
    }

    func updateUI(animated: Bool = false) {
        if viewModel.isLookingUpLinkAccount {
            emailElement.startAnimating()
        } else {
            emailElement.stopAnimating()
        }

        form.toggleChild(emailElement, show: viewModel.shouldShowEmailField, animated: animated)
        form.toggleChild(phoneNumberElement, show: viewModel.shouldShowPhoneField, animated: animated)
        form.toggleChild(legalTermsElement, show: viewModel.shouldShowLegalTerms, animated: animated)

        // 2-way binding
        checkboxElement.isChecked = viewModel.saveCheckboxChecked
        
        let errorLabel = errorElement.view as? UILabel
        errorLabel?.text = viewModel.errorMessage
        form.toggleChild(errorElement, show: viewModel.errorMessage != nil, animated: animated)
    }

}

extension LinkInlineSignupView: ElementDelegate {

    func didUpdate(element: Element) {
        if element === checkboxElement {
            viewModel.saveCheckboxChecked = checkboxElement.isChecked
        } else if element === emailElement {
            switch emailElement.validationState {
            case .valid:
                viewModel.emailAddress = emailElement.emailAddressString
            case .invalid(_):
                viewModel.emailAddress = nil
            }
        } else if element === phoneNumberElement {
            viewModel.phoneNumber = phoneNumberElement.phoneNumber
        }
    }

    func didFinishEditing(element: Element) {
        // No-op: Updates already handled in `didUpdate(element:)`.
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
