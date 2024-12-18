//
//  LinkInlineSignupElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

final class LinkInlineSignupElement: Element {
    let collectsUserInput: Bool = true

    private let signupView: LinkInlineSignupView

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
        accountService: LinkAccountServiceProtocol
    ) {
        self.init(viewModel: LinkInlineSignupViewModel(
            configuration: configuration,
            showCheckbox: showCheckbox,
            accountService: accountService,
            linkAccount: linkAccount,
            country: country
        ))
    }

    init(viewModel: LinkInlineSignupViewModel) {
        self.signupView = LinkInlineSignupView(viewModel: viewModel)
        self.signupView.delegate = self
    }

}

extension LinkInlineSignupElement: LinkInlineSignupViewDelegate {

    func inlineSignupViewDidUpdate(_ view: LinkInlineSignupView) {
        delegate?.didUpdate(element: self)
    }

}
