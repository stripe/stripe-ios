//
//  LinkInlineSignupElement.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

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

    func updateBrand(_ brand: LinkBrand) {
        signupView.updateBrand(brand)
    }

    convenience init(
        configuration: PaymentElementConfiguration,
        brand: LinkBrand,
        linkAccount: PaymentSheetLinkAccount?,
        country: String?,
        showCheckbox: Bool,
        accountService: LinkAccountServiceProtocol,
        resolvedLinkBrand: @escaping (PaymentSheetLinkAccount?) -> LinkBrand,
        allowsDefaultOptIn: Bool,
        signupOptInFeatureEnabled: Bool,
        signupOptInInitialValue: Bool,
        analyticsHelper: PaymentSheetAnalyticsHelper? = nil
    ) {
        self.init(viewModel: LinkInlineSignupViewModel(
            configuration: configuration,
            brand: brand,
            showCheckbox: showCheckbox,
            accountService: accountService,
            resolvedLinkBrand: resolvedLinkBrand,
            allowsDefaultOptIn: allowsDefaultOptIn,
            signupOptInFeatureEnabled: signupOptInFeatureEnabled,
            signupOptInInitialValue: signupOptInInitialValue,
            linkAccount: linkAccount,
            country: country,
            analyticsHelper: analyticsHelper
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
