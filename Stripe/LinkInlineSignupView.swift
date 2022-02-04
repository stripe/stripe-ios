//
//  LinkInlineSignupView.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

protocol LinkInlineSignupViewDelegate: AnyObject {
    func inlineSignupViewDidUpdate(_ view: LinkInlineSignupView)
}

/// For internal SDK use only
@objc(STP_Internal_LinkInlineSignupView)
final class LinkInlineSignupView: UIView {

    weak var delegate: LinkInlineSignupViewDelegate?

    let viewModel: LinkSignupViewModel

    private(set) lazy var checkboxElement = CheckboxElement(merchantName: viewModel.merchantName)

    private(set) lazy var emailElement = LinkEmailElement(defaultValue: viewModel.emailAddress)

    private(set) lazy var phoneNumberElement = LinkPhoneNumberElement()

    private lazy var form = FormElement(elements: [
        checkboxElement,
        emailElement,
        phoneNumberElement
    ])

    init(viewModel: LinkSignupViewModel) {
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
        tintColor = .linkBrand
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

        // 2-way binding
        checkboxElement.isChecked = viewModel.saveCheckboxChecked
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

extension LinkInlineSignupView: LinkSignupViewModelDelegate {

    func signupViewModelDidUpdate(_ viewModel: LinkSignupViewModel) {
        updateUI(animated: true)
        delegate?.inlineSignupViewDidUpdate(self)
    }

}
