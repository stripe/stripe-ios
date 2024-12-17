//
//  LinkInlineSignupElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

// TODO: Refactor this to be a ContainerElement and contain its sub-elements.
final class LinkInlineSignupElement: PaymentMethodElement {
    let collectsUserInput: Bool = true

    let signupView: LinkInlineSignupView

    lazy var view: UIView = {

        return FormView(viewModel: .init(elements: [signupView],
                                         bordered: viewModel.bordered,
                                         theme: viewModel.configuration.appearance.asElementsTheme))
    }()

    var viewModel: LinkInlineSignupViewModel {
        return signupView.viewModel
    }

    weak var delegate: ElementDelegate?

    var isChecked: Bool {
        return viewModel.saveCheckboxChecked
    }

    var action: LinkInlineSignupViewModel.Action? {
        return viewModel.action
    }

    convenience init(
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        country: String?,
        showCheckbox: Bool,
        previousCustomerInput: IntentConfirmParams?
    ) {
        self.init(viewModel: LinkInlineSignupViewModel(
            configuration: configuration,
            showCheckbox: showCheckbox,
            accountService: LinkAccountService(apiClient: configuration.apiClient),
            previousCustomerInput: previousCustomerInput?.linkInlineSignupCustomerInput,
            linkAccount: linkAccount,
            country: country
        ))
    }

    init(viewModel: LinkInlineSignupViewModel) {
        self.signupView = LinkInlineSignupView(viewModel: viewModel)
        self.signupView.delegate = self
    }

    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        params.linkInlineSignupCustomerInput = .init(
            phoneNumber: signupView.phoneNumberElement.phoneNumber,
            name: signupView.nameElement.text,
            email: signupView.emailElement.emailAddressString,
            checkboxSelected: signupView.checkboxElement.isChecked
        )
        return params
    }
}

extension LinkInlineSignupElement: LinkInlineSignupViewDelegate {

    func inlineSignupViewDidUpdate(_ view: LinkInlineSignupView) {
        delegate?.didUpdate(element: self)
    }

}
