//
//  LinkInlineSignupElement.swift
//  StripeiOS
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

final class LinkInlineSignupElement: Element {

    private let signupView: LinkInlineSignupView

    lazy var view: UIView = {
        return FormView(viewModel: .init(elements: [signupView], bordered: true))
    }()

    var viewModel: LinkSignupViewModel {
        return signupView.viewModel
    }

    weak var delegate: ElementDelegate?

    var isChecked: Bool {
        return viewModel.saveCheckboxChecked
    }

    var signupDetails: (PaymentSheetLinkAccount, PhoneNumber)? {
        return viewModel.signupDetails
    }

    convenience init(configuration: PaymentSheet.Configuration) {
        self.init(viewModel: .init(
            merchantName: configuration.merchantDisplayName,
            accountService: LinkAccountService(apiClient: configuration.apiClient)
        ))
    }

    init(viewModel: LinkSignupViewModel) {
        self.signupView = LinkInlineSignupView(viewModel: viewModel)
        self.signupView.delegate = self
    }

}

extension LinkInlineSignupElement: LinkInlineSignupViewDelegate {

    func inlineSignupViewDidUpdate(_ view: LinkInlineSignupView) {
        delegate?.didUpdate(element: self)
    }

}
